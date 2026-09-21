use CampusFlow_Try;
go


--                       C  R  U  D


--                    1-C R E A T E

create or alter procedure usp_AddNewSemester
                        @SemesterName nvarchar(50),
                        @Description nvarchar(max) =null,
                        @SemesterStartDate dateTime2(0) ,
                        @SemesterEndDate datetime2(0),
                        @SemesterActualEndDate DateTime2(0)=null,
                        @EnrollmentStartDate datetime2(0),
                        @EnrollmentEndDate DateTime2(0),
                        @Status tinyint=0,--Upcoming
                        @IsActive bit=1,
                        @CreatedByUserID int,
                        @CreationDate DateTime2(0) =null,
                        @NewSemesterID int output
As
Begin
   Set nocount on;
   insert into Semesters(Name,Description,SemesterStartDate,SemesterEndDate,SemesterActualEndDate,EnrollmentStartDate,EnrollmentEndDate,Status,IsActive,CreatedByUserID,CreationDate)
   values(@SemesterName,@Description,@SemesterStartDate,@SemesterEndDate,@SemesterActualEndDate,@EnrollmentStartDate,@EnrollmentEndDate,@Status,@IsActive,@CreatedByUserID,IsNull(@CreationDate ,SysDateTime()));

   Set @NewSemesterID=SCOPE_IDENTITY();

End;
go

--                    2-R E A D

create or alter procedure usp_GetSemesterBySemesterID
                            @SemesterID int
As
Begin 
       Set nocount on;
       Select 
             SemesterID,
             Name,
             Description,
             SemesterStartDate,
             SemesterEndDate,
             SemesterActualEndDate,
             EnrollmentStartDate,
             EnrollmentEndDate,
             Status,
             IsActive,
             CreatedByUserID,
             CreationDate
       From Semesters
       where SemesterID=@SemesterID;
End;

go

create or alter procedure usp_GetSemesterBySemesterName
                            @SemesterName nvarchar(50)
As
Begin
       Set nocount on;
       Select 
             SemesterID,
             Name,
             Description,
             SemesterStartDate,
             SemesterEndDate,
             SemesterActualEndDate,
             EnrollmentStartDate,
             EnrollmentEndDate,
             Status,
             IsActive,
             CreatedByUserID,
             CreationDate
       From Semesters
       where Name=@SemesterName;
End;
go

create or alter procedure usp_GetAllSemesters
                          @SemesterName nvarchar(100)=null,
                          @SemesterStartDate DateTime2(0)=null,
                          @SemesterEndDate   DateTime2(0)=null,
                          @SemesterActualEndDate DateTime2(0)=null,
                          @EnrollmentStartDate   DateTime2(0)=null,
                          @EnrollmentEndDate    DateTime2(0)=null,
                          @Status tinyint =null,
                          @IsActive tinyint =null,
                          @CreatedByUserID int =null,
                          @IgnoreSemesterActualEndDate bit =1
As
Begin
      Set nocount on;
      Select 
             SemesterID,
             Name,
             Description,
             SemesterStartDate,
             SemesterEndDate,
             SemesterActualEndDate,
             EnrollmentStartDate,
             EnrollmentEndDate,
             Status,
             IsActive,
             CreatedByUserID,
             CreationDate
       From Semesters
       where (@SemesterName is null or Name like '%'+@SemesterName+'%')
       And   (@SemesterStartDate is null or @SemesterStartDate <=SemesterStartDate)
       And   (@SemesterEndDate is null or @SemesterEndDate >=SemesterEndDate)
       And   (@IgnoreSemesterActualEndDate =1 or((@SemesterActualEndDate is null and SemesterActualEndDate is null) or @SemesterActualEndDate >=SemesterActualEndDate))
       And   (@EnrollmentStartDate is null or @EnrollmentStartDate <=EnrollmentStartDate)
       And   (@EnrollmentEndDate is null or @EnrollmentEndDate>=EnrollmentEndDate)
       And   (@Status is null or @Status=Status)
       And   (@IsActive is null or @IsActive=IsActive)
       And   (@CreatedByUserID is null or @CreatedByUserID=CreatedByUserID)
End;
go


--                    1-U P D A T E
create or alter procedure usp_UpdateSemesterInfoBySemesterID
                            @SemesterID int,
                            @SemesterName nvarchar(50),
                            @Description nvarchar(max),
                            @SemesterStartDate dateTime2(0) ,
                            @SemesterEndDate datetime2(0),
                            @EnrollmentStartDate datetime2(0),
                            @EnrollmentEndDate DateTime2(0),
                            @IsActive bit
                           
As
Begin 
      Set NoCount On;

      Update Semesters
      Set 
             Name=@SemesterName,
             Description=@Description,
             SemesterStartDate=@SemesterStartDate,
             SemesterEndDate=@SemesterEndDate,
             EnrollmentStartDate=@EnrollmentStartDate,
             EnrollmentEndDate=@EnrollmentEndDate,
             IsActive=@IsActive
       where SemesterID=@SemesterID
       And   IsActive=1;
      select @@ROWCOUNT as RowsEffected;
End;
go

create or alter procedure usp_SetSemesterActualEndDate
                            @SemesterID int,
                            @SemesterActualEndDate DateTime2(0)

                           
As
Begin 
       Set nocount on;
        declare @SemesterStartDate datetime2(0)=(select SemesterStartDate From Semesters where SemesterID=@SemesterID);
        declare @ErrorMessage nvarchar(max);
       
       if @SemesterActualEndDate<=@SemesterStartDate
           Begin 
              Set @ErrorMessage=FORMATMESSAGE('Semester End Date Can Not Be Less  Then or equal to Semster Start Date: %s',Cast(@SemesterStartDate as nvarchar(20)));
              throw 50001,@ErrorMessage,1;
           End;

       if @SemesterActualEndDate<=SysDateTime()
          Begin     
               Update Semesters
               Set SemesterActualEndDate=@SemesterActualEndDate
               where SemesterID=@SemesterID
               and   IsActive=1;
                exec usp_SetSemesterStatus
                             @SemesterID=@SemesterID,
                             @SemesterStatus=2;
          End
      else
          Begin     
               Update Semesters
               Set SemesterActualEndDate=@SemesterActualEndDate
               where SemesterID=@SemesterID
               and   IsActive=1;
               exec usp_SetSemesterStatus
                             @SemesterID=@SemesterID,
                             @SemesterStatus=1;
          End
          
       select @@ROWCOUNT as RowsEffected;
End;
go

create or alter procedure usp_SetSemesterStatus
                            @SemesterID int,
                            @SemesterStatus tinyint
                           
As
Begin 
       Set nocount on;

       declare @ErrorMessage nvarchar(max);
       declare @SemesterStartDate DateTime2(0)=(select SemesterStartDate from Semesters where SemesterID=@SemesterID);
       declare @SemesterActualEndDate DateTime2(0)=(select SemesterActualEndDate from Semesters where SemesterID=@SemesterID);
     
       if @SemesterStatus=0 and  @SemesterActualEndDate<=SysDateTime()
            Begin
                 Set @ErrorMessage=FORMATMESSAGE('Semester With ID %d Already Ended in %s You Cant Set it to Upcomming',@SemesterID,Cast(@SemesterActualEndDate as nvarchar(20)));
                 Throw 50001,@ErrorMessage,1;
             End
       if @SemesterStatus =0 and @SemesterStartDate<=SysDateTime()
             Begin
                 Set @ErrorMessage=FORMATMESSAGE('Semester With ID %d Already Started in %s You Cant Set it to Upcomming',@SemesterID,Cast(@SemesterStartDate as nvarchar(20)));
                 Throw 50002,@ErrorMessage,1;
             End
       if  @SemesterStatus =1 and @SemesterActualEndDate<SysDateTime()
             Begin
                 Set @ErrorMessage=FORMATMESSAGE('Semester With ID %d Already Ended in %s You Cant Set it to Active',@SemesterID,Cast(@SemesterActualEndDate as nvarchar(20)));--here it will not enter this body if it is null so the cast is safe
                 Throw 50003,@ErrorMessage,1;
             End
        if  @SemesterStatus =1 and @SemesterStartDate>SysDateTime()
             Begin
                 Set @ErrorMessage=FORMATMESSAGE('Semester With ID %d Starts in %s not today, You Cant Set it to Active',@SemesterID,Cast(@SemesterStartDate as nvarchar(20)));--here it will not enter this body if it is null so the cast is safe
                 Throw 50004,@ErrorMessage,1;
             End
       if @SemesterStatus =2 and @SemesterStartDate>SYSDATETIME() 
             Begin
                 Set @ErrorMessage=FORMATMESSAGE('Semester With ID %d hasent started yet  You Cant Set it to completed',@SemesterID);
                 Throw 50005,@ErrorMessage,1;
             End
       if @SemesterStatus =2 and  @SemesterActualEndDate is null
             Begin
                 Set @ErrorMessage=FORMATMESSAGE('Semester With ID %d hasent Ended yet *There is no Actual End Date* You Cant Set it to completed',@SemesterID);
                 Throw 50006,@ErrorMessage,1;
             End
            
         update Semesters
         Set Status=@SemesterStatus
         where SemesterID=@SemesterID
         and   IsActive=1;
         select @@ROWCOUNT as RowsEffected;

End;




--                  4-D E L E T E 

go
create or alter Procedure usp_DeleteSemesterBySemesterID
                @SemesterID int
As
Begin
Set nocount on;
      Update Semesters
      Set IsActive=0
      where SemesterID=@SemesterID
      And   IsActive=1;
Select @@ROWCOUNT as RowsEffected
end;

go
create or alter Procedure usp_DeleteSemesterBySemesterName
                @SemesterName nvarchar(50)
As
Begin
     Set nocount on;
      Update Semesters
      Set IsActive=0
      where Name=@SemesterName
      And   IsActive=1;

Select @@ROWCOUNT as RowsEffected
end;

go 
create or alter Trigger trg_SoftDeleteSemester
On Semesters
instead of delete
As
Begin 
       Set nocount on;
        Update S
        Set S.IsActive=0
        from Semesters S
        Inner Join Deleted D
        On S.SemesterID=D.SemesterID
        where S.IsActive=1;
End;

----------------------------------------------------------------------------------------------
go

create or alter procedure usp_ChangeSemesterActiveStatus
                              @SemesterID int,
                              @NewSemesterActiveStatus bit
As
Begin
       Set nocount on;

       update Semesters
       Set IsActive=@NewSemesterActiveStatus
       where SemesterID=@SemesterID

       Select @@ROWCOUNT as RowsEffected;
End;
go
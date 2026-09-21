use CampusFlow_Try;
go



create table Departments
(
DepartmentID int identity(1,1),
DepartmentName nvarchar(100) not null,
DepartmentCode nvarchar(100) not null,
HeadOfDepartmentID int null,
IsActive bit not null default 1,
CreatedByUserID int not null,
CreationDate DateTime2(0) not null
constraint df_DepartmentsCreationDate default SysDateTime(),
constraint FK_Departments_Users foreign key(CreatedByUserID)references Users(UserID),
constraint PK_Departments Primary key(DepartmentID)
)
go
create unique nonclustered index Idx_HeadOfDepartmentID
On Departments (HeadOfDepartmentID)
where HeadOfDepartmentID is not null
and   IsActive=1;
go

create unique nonclustered index idx_UniqueDepartmentCode
On Departments(DepartmentCode)
where IsActive=1;
go

create unique nonclustered index idx_UniqueDepartmentName
On Departments(DepartmentName)
where IsActive=1;
go
--                   C R U D

--                1-C R E A T E

create or alter procedure usp_AddNewDepartment
                     @DepartmentName nvarchar(100),
                     @DepartmentCode nvarchar(100),
                     @HeadOfDepartmentID int=null,
                     @IsActive bit=1,
                     @CreatedByUserID int,
                     @CreationDate datetime2(0) =null,
                     @NewDepartmentID int output
as
Begin
     
     set nocount on;
     if @HeadOfDepartmentID is not null
          Begin 
              exec usp_CheckHeadOfDepartmentActive
                    @HeadOfDepartmentID=@HeadOfDepartmentID;

              exec usp_CheckHeadOfDepartmentTaken
                    @HeadOfDepartmentID=@HeadOfDepartmentID;
          End;
     insert into Departments(DepartmentName,DepartmentCode,HeadOfDepartmentID,IsActive,CreatedByUserID,CreationDate)
     values(@DepartmentName,@DepartmentCode,@HeadOfDepartmentID,@IsActive,@CreatedByUserID,IsNull(@CreationDate,SysDateTime()));

     select @NewDepartmentID=SCOPE_IDENTITY();
End;
go



--           2-R E A D

create or alter procedure usp_GetDepartmentInfoByDepartmentID 
                              @DepartmentID int
As
Begin
         set nocount on;
         Select  DepartmentID,
                 DepartmentName,
                 DepartmentCode,
                 HeadOfDepartmentID,
                 IsActive,
                 CreatedByUserID,
                 CreationDate
         from Departments
         where DepartmentID=@DepartmentID
End;

go 
create or alter procedure usp_GetDepartmentInfoByDepartmentName 
                              @DepartmentName nvarchar(100)
As
Begin
         set nocount on;
         Select  DepartmentID,
                 DepartmentName,
                 DepartmentCode,
                 HeadOfDepartmentID,
                 IsActive,
                 CreatedByUserID,
                 CreationDate
         from Departments
         where DepartmentName=@DepartmentName
End;

go 
create or alter procedure usp_GetDepartmentInfoByDepartmentCode
                              @DepartmentCode nvarchar(100)
As
Begin
         set nocount on;
         Select  DepartmentID,
                 DepartmentName,
                 DepartmentCode,
                 HeadOfDepartmentID,
                 IsActive,
                 CreatedByUserID,
                 CreationDate
         from Departments
         where DepartmentCode=@DepartmentCode
End;

go 
create or alter procedure usp_GetDepartmentInfoByHeadOfDepartmentID 
                              @HeadOfDepartmentID int
As
Begin
         set nocount on;
         Select  DepartmentID,
                 DepartmentName,
                 DepartmentCode,
                 HeadOfDepartmentID,
                 IsActive,
                 CreatedByUserID,
                 CreationDate
         from Departments
         where (
                     HeadOfDepartmentID=@HeadOfDepartmentID 
                or   (HeadOfDepartmentID is null and @HeadOfDepartmentID is null)
                )
         and   IsActive=1;
        
End;

go 
create or alter procedure usp_GetAllDepartments
                              @CreatedByUserID int=null,
                              @CreationDate DateTime2(0)=null
As
Begin
         set nocount on;
         Select  DepartmentID,
                 DepartmentName,
                 DepartmentCode,
                 HeadOfDepartmentID,
                 IsActive,
                 CreatedByUserID,
                 CreationDate
         from Departments
         where (@CreatedByUserID is null or CreatedByUserID=@CreatedByUserID)
         And   (@CreationDate is null or 
                (Year(@CreationDate)=Year(CreationDate)
                 and
                 Month(@CreationDate)=Month(CreationDate)
                 and
                 Day(@CreationDate)=Day(CreationDate)
                 )
                 );

End;
go


--             3- U P D A T E

create or alter procedure usp_UpdateDepartmentInfoByDepartmentID
                              @DepartmentID int,
                              @DepartmentName nvarchar(100),
                              @DepartmentCode nvarchar(100),
                              @HeadOfDepartmentID int
As
Begin
        set nocount on;

           if @HeadOfDepartmentID is not null
             Begin
              exec usp_CheckHeadOfDepartmentActive 
                      @HeadOfDepartmentID =@HeadOfDepartmentID;
              exec usp_CheckHeadOfDepartmentTaken
                     @HeadOfDepartmentID=@HeadOfDepartmentID,
                     @ExcludeDepartmentID=@DepartmentID;
              End;
        Update  Departments
         Set     
                 DepartmentName=@DepartmentName,
                 DepartmentCode=@DepartmentCode,
                 HeadOfDepartmentID=@HeadOfDepartmentID
         where DepartmentID=@DepartmentID
         and   IsActive=1;
         select @@ROWCOUNT as RowsEffected;

End;
go 

create or alter procedure usp_CheckHeadOfDepartmentActive 
                                    @HeadOfDepartmentID int
As
Begin
     Set nocount on;

     declare @ErrorMessage nvarchar(max);

if exists  ( select 1
             from Instructors
             where @HeadOfDepartmentID=InstructorID
             And  IsActive=0
           )
           Begin
            Set @ErrorMessage=FORMATMESSAGE('Instructor With ID %d Is no Longer an Active Account in the system , You Cant Set It As A Head of a department ',@HeadOfDepartmentID);
            throw 50001,@ErrorMessage,1;
           End;
End;
go 

create or alter procedure usp_CheckHeadOfDepartmentTaken
                                   @HeadOfDepartmentID int,
                                   @ExcludeDepartmentID int=null
As
Begin
      set nocount on;
      
      declare @ErrorMessage nvarchar(max);
      declare @OwnerDepartmentID int;
      
      select @OwnerDepartmentID= DepartmentID
      From Departments
      where HeadOfDepartmentID=@HeadOfDepartmentID
      And   (@ExcludeDepartmentID is null or DepartmentID!=@ExcludeDepartmentID)
      And   IsActive=1;
      
     if @OwnerDepartmentID is not null
               Begin
                 Set @ErrorMessage=FORMATMESSAGE('Head of Department With ID %d Is Heading Department with ID : %d',@HeadOfDepartmentID,@OwnerDepartmentID);
                 Throw 50002,@ErrorMessage,1;
               End;
End;

go

create or alter procedure usp_ChangeDepartmentActiveStatus
                                @DepartmentID int,
                                @NewActiveStatus bit,
                                @ChangedByUserID int--for logging latter

As
Begin 
  Set nocount on;
  Declare @ErrorMessage nvarchar(max);

  if not exists (select 1 from Departments where DepartmentID=@DepartmentID)
    Begin
            Set @ErrorMessage=FORMATMESSAGE('Department With ID %d Is Not in The DataBase',@DepartmentID);
            Throw 50001,@ErrorMessage,1;
    End;

   Declare @DepartmentCurrentActiveStatus bit;
   select  @DepartmentCurrentActiveStatus =IsActive
           From    Departments
           where   DepartmentID=@DepartmentID;
      
           if @NewActiveStatus =@DepartmentCurrentActiveStatus
                             return;

            if @DepartmentCurrentActiveStatus=0 and @NewActiveStatus=1
                Begin
                    Declare @HeadOfDepartmentID int;
                    Select @HeadOfDepartmentID=HeadOfDepartmentID
                    From Departments
                    where DepartmentID=@DepartmentID;
                    if @HeadOfDepartmentID is not null
                         Begin           
                            exec usp_CheckHeadOfDepartmentActive
                                       @HeadOfDepartmentID=@HeadOfDepartmentID;
                            exec usp_CheckHeadOfDepartmentTaken
                                       @HeadOfDepartmentID=@HeadOfDepartmentID;
                          End;
                End;
    
    update Departments
    Set IsActive=@NewActiveStatus
    Where DepartmentID=@DepartmentID;

    Select @@ROWCOUNT as RowsEffected;

End;
go

--this is exists in file called Campus-Flow MyTypes.sql
--create Type dbo.IDsList as Table(ID int not null)
--go


create or alter procedure usp_ChangeDepartmentHead
                                   @DepartmentID int,
                                   @NewHeadOfDepartmentID int =null
As
Begin 
          if @NewHeadOfDepartmentID is not null
               Begin
                   exec usp_CheckHeadOfDepartmentActive
                            @HeadOfDepartmentID=@NewHeadOfDepartmentID;

                   exec usp_CheckHeadOfDepartmentTaken 
                                        @HeadOfDepartmentID=@NewHeadOfDepartmentID,
                                        @ExcludeDepartmentID=@DepartmentID;
               End;

          update Departments
          Set HeadOfDepartmentID=@NewHeadOfDepartmentID
          where DepartmentID=@DepartmentID
          And IsActive=1;

          Select @@ROWCOUNT as RowsEffected;
End;
go

create or alter procedure usp_DropDepartmentsHead
                           @DepartmentsID dbo.IDsList Readonly
As
Begin 

     Set Nocount on;
       
     update Departments
     Set HeadOfDepartmentID=null
     where DepartmentID in (Select ID from @DepartmentsID)
     and   IsActive=1;
     Select @@ROWCOUNT as RowsEffected;
End;
go
--         4- D E L E T E

create or alter procedure usp_DeleteDepartmentByDepartmentID
                              @DepartmentID int
As
Begin
         set nocount on;
         Update  Departments
         Set  
                 IsActive=0
         where DepartmentID=@DepartmentID
         and   IsActive=1;

         select @@ROWCOUNT as RowsEffected;
End;
go

create or alter trigger trg_SoftDeleteDepartment
On Departments
instead of delete
As
Begin
        set nocount on;
        Update  Dep
         Set  
                 Dep.IsActive=0
         From Departments Dep
         inner Join Deleted D
         On Dep.DepartmentID=D.DepartmentID
         and   Dep.IsActive=1;
End;
go


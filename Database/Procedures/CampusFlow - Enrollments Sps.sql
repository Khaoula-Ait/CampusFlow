use CampusFlow_Try;
go


--			C    R    U    D

--          Checks

create or alter procedure usp_CheckAlreadyExistingEnrollment
                                  @StudentID int,
                                  @CourseSectionID int
As
Begin
       Set NOCOUNT ON;

       declare @ErrorMessage nvarchar(max);
       declare @EnrollmentStatus tinyint;
       declare @EnrollmentID int;

       select @EnrollmentID=EnrollmentID,
              @EnrollmentStatus=EnrollmentStatus
       from Enrollments
       where StudentID=@StudentID
       And   CourseSectionID=@CourseSectionID
       And   EnrollmentStatus in (1,2);

       if @EnrollmentStatus =1
           Begin 
              Set @ErrorMessage=FORMATMESSAGE('Student With ID [ %d ] is Already Enrolled in Course Section with ID [ %d ] with The Enrollment by ID [ %d ]',@StudentID,@CourseSectionID,@EnrollmentID);
              Throw 50001,@ErrorMessage ,1;
           End
       else if @EnrollmentStatus =2
           Begin 
              Set @ErrorMessage=FORMATMESSAGE('Student With ID [ %d ] has a completed Enrollment with ID [ %d ] in Course Section with ID [ %d ]',@StudentID,@EnrollmentID,@CourseSectionID);
              Throw 50001,@ErrorMessage ,1;
           End;

End;
go


--             1-C R E A T E

create or alter procedure usp_AddNewEnrollment
                             @StudentID int,
                             @CourseSectionID int,
                             @EnrollmentStartDate DateTime2(0)=null,
                             @EnrollmentActualEndDate DateTime2(0)=null,
                             @GradeLetter varchar(2) =null,
                             @GPAPoint decimal(3,2)=null,
                             @Score decimal(5,2)=null,
                             @EnrollmentStatus tinyint =1,
                             @DropDate DateTime2(0)=null,
                             @CreatedByUserID int ,
                             @CreationDate DateTime2(0)=null,
                             @NewEnrollmentID int output
As
Begin
      Set NOCOUNT ON;

      
                   exec usp_CheckAlreadyExistingEnrollment
                              @StudentID=@StudentID,
                              @CourseSectionID=@CourseSectionID;

      insert into Enrollments(StudentID,CourseSectionID,EnrollmentStartDate,EnrollmentActualEndDate,GradeLetter,GPAPoint,Score,EnrollmentStatus,DropDate,CreatedByUserID,CreationDate)
      values(@StudentID,@CourseSectionID,IsNull(@EnrollmentStartDate,SysDateTime()),@EnrollmentActualEndDate,@GradeLetter,@GPAPoint,@Score,@EnrollmentStatus,@DropDate,@CreatedByUserID,IsNull(@CreationDate,SysDateTime()));


      select @NewEnrollmentID=SCOPE_IDENTITY();
End;
go


--           2-R  E  A  D

create or alter procedure usp_GetEnrollmentByEnrollmentID
                                         @EnrollmentID int
As
Begin 
       Set NOCOUNT ON;

       Select  EnrollmentID,
               StudentID,
               CourseSectionID,
               EnrollmentStartDate,
               EnrollmentActualEndDate,
               Score,
               GPAPoint,
               GradeLetter,     
               EnrollmentStatus,
               DropDate,
               CreatedByUserID,
               CreationDate
         From Enrollments
         where EnrollmentID=@EnrollmentID;

End;
go



create or alter procedure usp_GetAllEnrollments
                             @StudentID int=null,
                             @CourseSectionID int=null,
                             @EnrollmentStartDateAfter DateTime2(0)=null,
                             @EnrollmentStartDateBefore DateTime2(0)=null,
                             @EnrollmentStatus tinyint =null,
                             @CreatedByUserID int =null
As
Begin
     Set NOCOUNT ON;
     
       Select  EnrollmentID,
               StudentID,
               CourseSectionID,
               EnrollmentStartDate,
               EnrollmentActualEndDate,
               Score,
               GPAPoint,
               GradeLetter,     
               EnrollmentStatus,
               DropDate,
               CreatedByUserID,
               CreationDate
         From Enrollments
         where (@StudentID is null or StudentID=@StudentID)
         And   (@CourseSectionID is null or CourseSectionID=@CourseSectionID)
         And   (@CreatedByUserID is null or CreatedByUserID=@CreatedByUserID)
         And   (@EnrollmentStatus is null or EnrollmentStatus=@EnrollmentStatus)
         And   (@EnrollmentStartDateAfter is null or  EnrollmentStartDate>=@EnrollmentStartDateAfter)
         And   (@EnrollmentStartDateBefore is null or EnrollmentStartDate <=@EnrollmentStartDateBefore);
End;
go

create or alter procedure usp_GetAllEnrollmentsByEnrollmentActualEndDate
                             @EnrollmentActualEndDate DateTime2(0)=null,
                             @EnrollmentActualEndDateAfter DateTime2(0)=null,
                             @EnrollmentActualEndDateBefore DateTime2(0)=null,
                             @EnrollmentActualEndDateNotAssinged bit =0
As
Begin
     Set NOCOUNT ON;
     
       Select EnrollmentID,
               StudentID,
               CourseSectionID,
               EnrollmentStartDate,
               EnrollmentActualEndDate,
               Score,
               GPAPoint,
               GradeLetter,     
               EnrollmentStatus,
               DropDate,
               CreatedByUserID,
               CreationDate
         From Enrollments
         where (@EnrollmentActualEndDate is null or EnrollmentActualEndDate=@EnrollmentActualEndDate)              
         And   (@EnrollmentActualEndDateAfter is null or  EnrollmentActualEndDate>@EnrollmentActualEndDateAfter)
         And   (@EnrollmentActualEndDateBefore is null or EnrollmentActualEndDate<@EnrollmentActualEndDateBefore)
         or    (@EnrollmentActualEndDateNotAssinged =1 and EnrollmentActualEndDate is null);
         
End;
go


create or alter procedure usp_GetAllEnrollmentsByDropDate
                             @DropDate DateTime2(0)=null,
                             @DropDateAfter DateTime2(0)=null,
                             @DropDateBefore DateTime2(0)=null,
                             @DropDateNotAssinged bit =0
As
Begin
     Set NOCOUNT ON;
     
       Select  EnrollmentID,
               StudentID,
               CourseSectionID,
               EnrollmentStartDate,
               EnrollmentActualEndDate,
               Score,
               GPAPoint,
               GradeLetter,     
               EnrollmentStatus,
               DropDate,
               CreatedByUserID,
               CreationDate
         From Enrollments
         where (@DropDate is null or DropDate=@DropDate)
         And   (@DropDateAfter is null or  DropDate> @DropDateAfter)
         And   (@DropDateBefore is null or  DropDate< @DropDateBefore)
         or    (@DropDateNotAssinged =1 and DropDate is null);
         
End;
go



create or alter procedure usp_GetAllEnrollmentsByGPAPoint
                             @GPAPoint decimal(3,2)=null,
                             @GPAPointGreaterThen decimal(3,2)=null,
                             @GPAPointLessThen    decimal(3,2)=null,
                             @GPAPointNotAssinged bit =0
As
Begin
     Set NOCOUNT ON;
     
       Select  EnrollmentID,
               StudentID,
               CourseSectionID,
               EnrollmentStartDate,
               EnrollmentActualEndDate,
               Score,
               GPAPoint,
               GradeLetter,     
               EnrollmentStatus,
               DropDate,
               CreatedByUserID,
               CreationDate
         From Enrollments
         where (@GPAPoint is null or GPAPoint=@GPAPoint)
         And   (@GPAPointGreaterThen is null or  GPAPoint> @GPAPointGreaterThen)
         And   (@GPAPointLessThen is null or GPAPoint< @GPAPointLessThen   )
         or    (@GPAPointNotAssinged =1 and GPAPoint is null);
         
End;
go




create or alter procedure usp_GetAllEnrollmentsByScore
                             @Score decimal(5,2)=null,
                             @ScoreGreaterThen decimal(5,2)=null,
                             @ScoreLessThen    decimal(5,2)=null,
                             @ScoreNotAssinged bit =0
As
Begin
     Set NOCOUNT ON;
     
       Select  EnrollmentID,
               StudentID,
               CourseSectionID,
               EnrollmentStartDate,
               EnrollmentActualEndDate,
               Score,
               GPAPoint,
               GradeLetter,     
               EnrollmentStatus,
               DropDate,
               CreatedByUserID,
               CreationDate
         From Enrollments
         where (@Score is null or Score=@Score)
         And   (@ScoreGreaterThen is null or Score> @ScoreGreaterThen)
         And   (@ScoreLessThen is null or Score< @ScoreLessThen   )
         or   (@ScoreNotAssinged =1 and Score is null);
         
End;
go




create or alter procedure usp_GetAllEnrollmentsByGradeLetter
                             @GradeLetter varchar(2)=null,
                             @GradeLetterNotAssinged bit =0
As
Begin
     Set NOCOUNT ON;
     
       Select  EnrollmentID,
               StudentID,
               CourseSectionID,
               EnrollmentStartDate,
               EnrollmentActualEndDate,
               Score,
               GPAPoint,
               GradeLetter,     
               EnrollmentStatus,
               DropDate,
               CreatedByUserID,
               CreationDate
         From Enrollments
         where (GradeLetter=@GradeLetter)
         or   (@GradeLetterNotAssinged =1 and GradeLetter is null);
         
End;
go


--          3-U P D A T E


-- this procedure will change the stored start date in case of a mistake 
-- here i will not check enrollment status but i will store old date + the user that 
--made the change letter in a log table
create or alter procedure usp_ChangeEnrollmentStartDate
                                @EnrollmentID int,
                                @NewEnrollmentStartDate DateTime2(0),
                                @ChangedByUserID int --For logging
As
Begin
      Set Nocount on;

      update Enrollments
      Set EnrollmentStartDate=@NewEnrollmentStartDate
      where EnrollmentID=@EnrollmentID;

      select @@ROWCOUNT As RowsEffected;

End;
go

create or alter procedure usp_SetEnrollmentStatusToCompleted
                             @EnrollmentID int,
                             @EnrollmentActualEndDate DateTime2(0),
                             @SetByUserID int --for logging
As
Begin
       Set Nocount on;

       declare @ErrorMessage nvarchar(max);

          if  exists(Select 1 
                    from Enrollments
                    where EnrollmentID=@EnrollmentID
                    And   EnrollmentStatus =2
                    )
           Begin

               Set @ErrorMessage=FORMATMESSAGE('Enrollment With ID [ %d ] is Already Completed',@EnrollmentID);
               Throw 50002,@ErrorMessage,1;
           End;
      if  exists(Select 1 
                    from Enrollments
                    where EnrollmentID=@EnrollmentID
                    And   EnrollmentStatus =0
                    )
           Begin

               Set @ErrorMessage=FORMATMESSAGE('Enrollment With ID [ %d ] is Droped, You Cant Set it To Completed',@EnrollmentID);
               Throw 50002,@ErrorMessage,1;
           End;

      if not exists(Select 1 
                    from Enrollments
                    where EnrollmentID=@EnrollmentID
                    And   Score is not null
                    And   GradeLetter is not null
                    And   GPAPoint is not null
                    )
           Begin

               Set @ErrorMessage=FORMATMESSAGE('You Have Not Set Enrollment Grade Yet , You Need To Set it for the Enrollment To Be Completed or you can Drop it');
               Throw 50001,@ErrorMessage,1;
           End;

       Update Enrollments
       Set EnrollmentActualEndDate=@EnrollmentActualEndDate,
           EnrollmentStatus=2
       where EnrollmentID=@EnrollmentID
       And   EnrollmentStatus=1;
       select @@ROWCOUNT As RowsEffected;
End;
go

create or alter procedure usp_DropEnrollment
                                @EnrollmentID int,
                                @EnrollmentDropDate Date,
                                @DropedByUserID int --for loggin
As
Begin 
         Set nocount on;
         declare @ErrorMessage nvarchar(max);

          if  exists(Select 1 
                    from Enrollments
                    where EnrollmentID=@EnrollmentID
                    And   EnrollmentStatus =0
                    )
           Begin

               Set @ErrorMessage=FORMATMESSAGE('Enrollment With ID [ %d ] is Already Droped :)',@EnrollmentID);
               Throw 50002,@ErrorMessage,1;
           End;
      if  exists(Select 1 
                    from Enrollments
                    where EnrollmentID=@EnrollmentID
                    And   EnrollmentStatus =2
                    )
           Begin

               Set @ErrorMessage=FORMATMESSAGE('Enrollment With ID [ %d ] is Completed, You Cant Drop it',@EnrollmentID);
               Throw 50003,@ErrorMessage,1;
           End;
         update Enrollments
         Set    DropDate=@EnrollmentDropDate,
                EnrollmentStatus=0
         Where  EnrollmentID=@EnrollmentID
         And    EnrollmentStatus=1;

         select @@ROWCOUNT As RowsEffected;
End;
go
                
create or alter Procedure usp_SetScore
                              @EnrollmentID int,
                              @Score decimal(5,2),
                              @SetByUserID int
As
Begin
      Set Nocount on;
      declare @ErrorMessage nvarchar(max);
      if exists(select 1 
                from Enrollments
                where EnrollmentID =@EnrollmentID
                And   EnrollmentStatus=0
                )
           Begin

               Set @ErrorMessage=FORMATMESSAGE('Enrollment With ID [ %d ] is Droped, You Cant Set its Score',@EnrollmentID);
               Throw 50001,@ErrorMessage,1;
           End;

        if exists(select 1 
                from Enrollments
                where EnrollmentID =@EnrollmentID
                And   EnrollmentStatus=2
                )
           Begin

               Set @ErrorMessage=FORMATMESSAGE('Enrollment With ID [ %d ] is Completed, You Cant Set its Score',@EnrollmentID);
               Throw 50002,@ErrorMessage,1;
           End;

       declare @GPAPoint decimal(3,2);
       declare @MinScore decimal(5,2);
       declare @MinNextScore decimal(5,2);
       declare @GradeLetter varchar(2);

      exec usp_GetGradeScoreInfoToCalculateGPAByScore
                   @Score=@Score,
                   @MinScore=@MinScore output,
                   @MinNextScore=@MinNextScore output,
                   @GPAPoint=@GPAPoint output,
                   @GradeLetter=@GradeLetter output;

    if @MinScore is null
          Begin
                 Set @ErrorMessage=FORMATMESSAGE('Score : %s Does Not Fall In Any Scale we Have ',Cast(@Score as nvarchar(5)));
                 Throw 60001,@ErrorMessage,1;
          End;

     declare @EnrollmentGPAPoint decimal(3,2);                 

     exec usp_CalculateGPA
               @Score=@Score,
               @MinNextScore=@MinNextScore ,
               @MinScore=@MinScore,
               @GPAPoint=@GPAPoint,
               @CalculatedGPA=@EnrollmentGPAPoint output;

     update Enrollments
     Set    Score=@Score,
            GPAPoint=@EnrollmentGPAPoint,
            GradeLetter=@GradeLetter
    Where EnrollmentID=@EnrollmentID
    And   EnrollmentStatus=1;

    Select @@ROWCOUNT as RowsEffected;

End;
go



--            4-D E L E T E

create or alter trigger trg_SoftDeleteEnrollment
On Enrollments
instead of delete
As
Begin 
     Set Nocount on;

     update E
     Set E.EnrollmentStatus=0,
         E.DropDate=GETDATE()
     from Enrollments E
     Inner join Deleted D
     On E.EnrollmentID=D.EnrollmentID
     And  E.EnrollmentStatus=1;
End;
go

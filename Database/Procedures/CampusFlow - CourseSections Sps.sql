use CampusFlow_Try;
go
Create table CourseSections
(
CourseSectionID int identity(1,1),
CourseID int not null,
InstructorID int null,--we can set instructor latter
SemesterID int not null,
DayOfWeek tinyint not null, --from 1 to 7 the section is thought one day a week
StartTime  Time(0) not null,
EndTime Time(0) not null,
RoomNumber nvarchar(10) not null,
Capacity smallint not null
constraint df_CourseSectionCapacity default 20,
IsActive bit not null
constraint df_IsActiveCourseSection default (1),
CreatedByUserID int not null,
CreationDate DateTime2(0) not null
constraint df_CourseSectionCreationDate default SysDateTime(),
constraint FK_CourseSections_Users foreign key(CreatedByUserID)references Users(UserID),
constraint chk_ValidCapacity check(Capacity>=0),
constraint chk_ValidSectionDateTime check(StartTime<EndTime),--here i can add in the settings table a minimum section time and check the diffrence between them
constraint chk_DayOfWeek check(DayOfWeek in (1,2,3,4,5,6,7)),
constraint chk_NonEmptyRoomNumber check(len(trim(RoomNumber))>0),
Constraint FK_Semesters_CourseSections foreign key(SemesterID) references Semesters(SemesterID),
Constraint FK_Instructors_CourseSections foreign key(InstructorID) references Instructors(InstructorID),
Constraint FK_Courses_CourseSections foreign key(CourseID) references Courses(CourseID),
constraint PK_CourseSections Primary Key (CourseSectionID)
)
go

create unique nonclustered index Idx_UniqueActiveCourseSectionRecordByInstructor_Semester_DOW_ST_ET
On CourseSections(InstructorID,SemesterID,DayOfWeek,StartTime,EndTime)
where InstructorID is not null
and   IsActive=1;
go 


Create unique nonclustered index Idx_UniqueActiveCourseSectionRecordByRoomNumber_Semester_DOW_ST_ET
On CourseSections(RoomNumber,SemesterID,DayOfWeek,StartTime,EndTime)
where  IsActive=1; 
go
--                   O   V   E   R   L   A   P

create or alter procedure usp_IsInstructorAlreadyBookedForThisTimeSlot
                             @InstructorID int,
                             @StartTime Time(0),
                             @EndTime Time(0),
                             @DayOfWeek tinyint,
                             @SemesterID int,
                             @ExecludeCourseSectionID int =null,
                             @IsBooked bit output

As
Begin 
   Set Nocount ON;
   

     if @InstructorID is null
        Begin
        Set @IsBooked=0;
        return;
        End
   declare @OverlapCounter int;
   select @OverlapCounter=Count(*)
   from CourseSections
   where  InstructorID=@InstructorID
   And   DayOfWeek=@DayOfWeek
   And   SemesterID=@SemesterID
   And   IsActive=1
   And  (@StartTime<EndTime and @EndTime>StartTime)
   And  (@ExecludeCourseSectionID is null or @ExecludeCourseSectionID!=CourseSectionID);
     if @OverlapCounter=0
            Set @IsBooked= 0;
     else 
            Set @IsBooked= 1;

End;
go 

create or alter procedure usp_IsRoomAlreadyBookedForThisTimeSlot
                             @RoomNumber nvarchar(10),
                             @StartTime Time(0),
                             @EndTime Time(0),
                             @DayOfWeek tinyint,
                             @SemesterID int,
                             @ExecludeCourseSectionID int =null,
                             @IsBooked bit output

As
Begin 
   Set Nocount ON;
   declare @ErrorMessage nvarchar(max);
   if len(trim(@RoomNumber))=0
     Begin
          Set @ErrorMessage='Room Number Cant be empty';
          Throw 50001,@ErrorMessage,1;
     End;

   declare @OverlapCounter int;
   select @OverlapCounter=Count(*)
   from CourseSections
   where 
         RoomNumber = @RoomNumber
   And   DayOfWeek=@DayOfWeek
   And   SemesterID=@SemesterID
   And   IsActive=1
   And   (@StartTime<EndTime and @EndTime>StartTime)
   And  (@ExecludeCourseSectionID is null or @ExecludeCourseSectionID!=CourseSectionID);

     
     if @OverlapCounter=0
           Set @IsBooked= 0;
     else 
            Set @IsBooked= 1;

End;
go

create or alter procedure usp_CheckCourseSectionAvailability
                           @InstructorID int =null,
                            @SemesterID int,
                            @DayOfWeek tinyint,
                            @StartTime time(0) ,
                            @EndTime time(0),
                            @RoomNumber nvarchar(10),
                            @ExecludeCourseSectionID int=null
As
Begin
 declare @BookedInstructor bit;
      declare @BookedRoom bit;
      declare @ErrorMessage nvarchar(100);
      
      if @InstructorID is not null 
         Begin
               exec usp_IsInstructorAlreadyBookedForThisTimeSlot
                            @InstructorID=@InstructorID,
                            @StartTime=@StartTime,
                            @EndTime=@EndTime,
                            @DayOfWeek=@DayOfWeek,
                            @SemesterID=@SemesterID,
                            @IsBooked=@BookedInstructor output;
                      if @BookedInstructor=1
                            Begin
                               Set @ErrorMessage=FORMATMESSAGE('Instructor With ID %d Is Book Between %s and %s',@InstructorID,cast(@StartTime as nvarchar(10)),Cast(@EndTime as nvarchar(10)));
                               throw 50001,@ErrorMessage,1;
                            End;
         End;

       exec usp_IsRoomAlreadyBookedForThisTimeSlot
                         @StartTime=@StartTime,
                         @EndTime=@EndTime,
                         @DayOfWeek=@DayOfWeek,
                         @RoomNumber=@RoomNumber,
                         @SemesterID=@SemesterID,
                         @IsBooked=@BookedRoom output;
       if @BookedRoom=1
           Begin
           Set @ErrorMessage=FORMATMESSAGE('Room With ID %s Is Book Between %s and %s',@RoomNumber,cast(@StartTime as nvarchar(10)),Cast(@EndTime as nvarchar(10)));
                 throw 50002,@ErrorMessage,1;
           End
End;
go
--                  C  R  U  D 

--                   1-C R E A T E
create or alter procedure usp_AddNewCourseSection
                            @CourseID int,
                            @InstructorID int =null,
                            @SemesterID int,
                            @DayOfWeek tinyint,
                            @StartTime time(0) ,
                            @EndTime time(0),
                            @RoomNumber nvarchar(10),
                            @Capacity smallint,
                            @IsActive bit =1,
                            @CreatedByUserID int,
                            @CreationDate DateTime2(0)=null,
                            @NewCourseSectionID int output
As
Begin
      Set NoCount On;
     
     exec usp_CheckCourseSectionAvailability
                     @InstructorID=@InstructorID,
                     @SemesterID =@SemesterID,
                     @DayOfWeek=@DayOfWeek,
                     @StartTime=@StartTime,
                     @EndTime=@EndTime,
                     @RoomNumber=@RoomNumber;
      
      insert into CourseSections(CourseID,InstructorID,SemesterID,DayOfWeek,StartTime,EndTime,RoomNumber,Capacity,IsActive,CreatedByUserID,CreationDate)
      values(@CourseID,@InstructorID,@SemesterID,@DayOfWeek,@StartTime,@EndTime,@RoomNumber,@Capacity,@IsActive,@CreatedByUserID,IsNull(@CreationDate,SysDateTime()));

      select @NewCourseSectionID=SCOPE_IDENTITY();
      return 1;
End;
go

--         2- R E A D


create or alter procedure usp_GetCourseSectionByCourseSectionID
                               @CourseSectionID int
As
Begin 
     Set NoCount ON;

     Select   CourseSectionID,
              CourseID,
              InstructorID,
              SemesterID,
              DayOfWeek,
              StartTime,
              EndTime,
              RoomNumber,
              Capacity,
              IsActive,
              CreatedByUserID,
              CreationDate
     From CourseSections
     where CourseSectionID=@CourseSectionID;
End;
go



create or alter procedure usp_GetAllCourseSections
                               @CourseID int=null,
                               @InstructorID int= null,
                               @SemesterID int=null,
                               @DayOfWeek tinyint =null,
                               @StartTime time(0)=null,
                               @EndTime Time(0) =null,
                               @RoomNumber nvarchar(10) =null,
                               @Capacity smallint =null,
                               @IsActive bit =null,
                               @CreatedByUserID int =null
As
Begin 
     Set NoCount ON;

     Select   CourseSectionID,
              CourseID,
              InstructorID,
              SemesterID,
              DayOfWeek,
              StartTime,
              EndTime,
              RoomNumber,
              Capacity,
              IsActive,
              CreatedByUserID,
              CreationDate
     From CourseSections
     where (@CourseID is null or CourseID=@CourseID)
     And   (@InstructorID is null or InstructorID=@InstructorID)
     And   (@SemesterID is null or SemesterID=@SemesterID)
     And   (@DayOfWeek is null or DayOfWeek=@DayOfWeek)
     And   (@StartTime is null or StartTime=@StartTime)
     And   (@EndTime is null or EndTime=@EndTime)
     And   (@RoomNumber is null or RoomNumber like '%'+@RoomNumber+'%')
     And   (@Capacity is null or Capacity=@Capacity)
     And   (@IsActive is null or IsActive=@IsActive)
     And   (@CreatedByUserID is null or CreatedByUserID=@CreatedByUserID)

End;

go

create or alter procedure usp_GetCourseSectionCapacity
                               @CourseSectionID int,
                               @IsActive bit=null
As
Begin 
     select Capacity
     from CourseSections
     where CourseSectionID=@CourseSectionID
     and (@IsActive is null or @IsActive=IsActive);
end;
go



--         3-U P D A T E
create or alter procedure usp_UpdateCourseSection
                          @CourseSectionID int,
                          @CourseID int,
                          @InstructorID int,
                          @SemesterID int,
                          @DayOfWeek tinyint,
                          @StartTime time(0) ,
                          @EndTime time(0),
                          @RoomNumber nvarchar(10),
                          @Capacity smallint
As

Begin

     Set NoCount ON;
      exec usp_CheckCourseSectionAvailability
                     @InstructorID=@InstructorID,
                     @SemesterID =@SemesterID,
                     @DayOfWeek=@DayOfWeek,
                     @StartTime=@StartTime,
                     @EndTime=@EndTime,
                     @RoomNumber=@RoomNumber,
                     @ExecludeCourseSectionID=@CourseSectionID;
     update CourseSections
     Set      CourseID=@CourseID,
              InstructorID=@InstructorID,
              SemesterID=@SemesterID,
              DayOfWeek=@DayOfWeek,
              StartTime=@StartTime,
              EndTime=@EndTime,
              RoomNumber=@RoomNumber,
              Capacity=@Capacity
     where CourseSectionID=@CourseSectionID
     and IsActive=1;


     select @@ROWCOUNT as RowsEffected
     return 1;
End;
go

create or alter procedure usp_ChangeCourseSectionActiveStatus
                                @CourseSectionID int,
                                @NewActiveStatus bit ,
                                @ChangedByUserID int
As
Begin

    Set nocount on;
    Declare @ErrorMessage nvarchar(max);
    if not exists (select 1 from CourseSections where CourseSectionID=@CourseSectionID)
              begin
                   Set @ErrorMessage=FORMATMESSAGE('Course Section With ID %d does NOT exist in the system',@CourseSectionID);
                   Throw 50001,@ErrorMessage,1;
              End;
      declare @CurrentActiveStatus bit =(Select IsActive From CourseSections where CourseSectionID=@CourseSectionID);
    
      if @CurrentActiveStatus=@NewActiveStatus
                  return;
      if @CurrentActiveStatus=0 and @NewActiveStatus =1
         Begin
              declare @InstructorID int;
              declare @RoomNumber nvarchar(10);
              declare @StartTime Time(0);
              declare @EndTime Time(0);
              declare @SemesterID int;
              declare @DayOfWeek tinyint;
              declare @InstructorBooked bit;
              declare @RoomBooked bit;
            Select 
                     @InstructorID=InstructorID,
                     @RoomNumber=RoomNumber,
                     @StartTime=StartTime,
                     @EndTime=EndTime,
                     @SemesterID=SemesterID,
                     @DayOfWeek= DayOfWeek
            From CourseSections
            where CourseSectionID=@CourseSectionID;
                        
           exec usp_CheckCourseSectionAvailability
                     @InstructorID=@InstructorID,
                     @SemesterID =@SemesterID,
                     @DayOfWeek=@DayOfWeek,
                     @StartTime=@StartTime,
                     @EndTime=@EndTime,
                     @RoomNumber=@RoomNumber,
                     @ExecludeCourseSectionID=@CourseSectionID;
         End;

      Update CourseSections
      Set IsActive=@NewActiveStatus
      Where CourseSectionID=@CourseSectionID;

      Select @@ROWCOUNT as RowsEffected;


End;
go

   

     
--         4- D E L E T E
create or alter procedure usp_DeleteCourseSection
                          @CourseSectionID int 
As

Begin
     Set NoCount ON;
     update CourseSections
     Set     IsActive=0
     where CourseSectionID=@CourseSectionID
     and IsActive=1;


     select @@ROWCOUNT as RowsEffected
End;
go

create or alter Trigger trg_SoftDeleteCourseSection
On CourseSections
instead of delete
As

Begin
     Set NoCount ON;
     update C
     Set     C.IsActive=0
     From CourseSections C
     inner join Deleted D
     On C.CourseSectionID=D.CourseSectionID
     and C.IsActive=1;

End;
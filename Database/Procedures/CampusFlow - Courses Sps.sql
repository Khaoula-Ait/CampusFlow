use CampusFlow_Try;
go 


Create table Courses
(CourseID int identity(1,1),
CourseName nvarchar(50) not null, --should that be unique??
CourseCode nvarchar(50) not null,
Description nvarchar(max) null,
Credit Decimal(4,2) not null,
DepartmentID int not null,
IsActive bit not null default 1,
CreatedByUserID int not null,
CreationDate DateTime2(0) not null
constraint df_CourseCreationDate default SysDateTime(),
constraint FK_Courses_Users foreign key(CreatedByUserID)references Users(UserID),
constraint chk_PositiveCredit check(Credit>=0.0),
constraint FK_Courses_Departments Foreign key(DepartmentID)References Departments(DepartmentID),
constraint PK_Courses Primary key(CourseID)
)
go

create unique nonclustered index Idx_UniqueActiveCourseCode
on Courses(CourseCode)
where IsActive=1;
go

--                       C   R   U   D                        --

--                     1-C R E A T E
create or alter procedure usp_AddNewCourse
                           @CourseName nvarchar(50),
                           @CourseCode nvarchar(50),
                           @CourseDescription nvarchar(max)=null,
                           @Credit decimal(4,2),
                           @DepartmentID int,
                           @IsActive bit =1,
                           @CreatedByUserID int,
                           @CreationDate DateTime2(0)=null,
                           @NewCourseID int output
As                         
Begin
     Set nocount ON;

     exec usp_CheckActiveCourseWithCode
                 @CourseCode=@CourseCode;

     insert into Courses(CourseName,CourseCode,Description,Credit,DepartmentID,IsActive,CreatedByUserID,CreationDate)
     values(@CourseName,@CourseCode,@CourseDescription,@Credit,@DepartmentID,@IsActive,@CreatedByUserID,IsNull(@CreationDate,SysDateTime()));

     select @NewCourseID=SCOPE_IDENTITY();
End;
go 


--                    2-R E A D
create or alter procedure usp_GetCourseByCourseID
                         @CourseID int
As
Begin
     Set Nocount ON;

     select 
            CourseID,
            CourseName,
            CourseCode,
            Description,
            Credit,
            DepartmentID,
            IsActive,
            CreatedByUserID,
            CreationDate
     from Courses
     where CourseID=@CourseID;
End;

go

create or alter procedure usp_GetCourseByCourseCode
                         @CourseCode nvarchar(50)
As
Begin
     Set Nocount ON;

     select 
            CourseID,
            CourseName,
            CourseCode,
            Description,
            Credit,
            DepartmentID,
            IsActive,
            CreatedByUserID,
            CreationDate
     from Courses
     where CourseCode=@CourseCode;
End;
go

create or alter procedure usp_GetAllCourses
                         @CourseName nvarchar(50)=null,
                         @Description nvarchar(max)=null,
                         @DepartmentID int=null,
                         @IsActive bit=null,
                         @Credit decimal(4,2)=null,
                         @CreatedByUserID int=null
As
Begin
     Set Nocount ON;

     select 
            CourseID,
            CourseName,
            CourseCode,
            Description,
            Credit,
            DepartmentID,
            IsActive,
            CreatedByUserID,
            CreationDate
     from Courses

     where (@CourseName is null or CourseName like '%'+@CourseName+'%')
     And   (@Description is null or Description like '%'+@Description+'%')
     And   (@DepartmentID is null or DepartmentID=@DepartmentID)
     And   (@IsActive is null or IsActive =@IsActive)
     And   (@Credit is null or Credit=@Credit)
     And   (@CreatedByUserID is null or CreatedByUserID=@CreatedByUserID);
End;
go



--               3-U P D A T E

create or alter procedure usp_CheckActiveCourseWithCode
                                    @CourseCode nvarchar(50),
                                    @ExcludeCourseID int=null
As
Begin
       Declare @ErrorMessage nvarchar(max);
          if  exists(select 1
                     from Courses
                     where (@ExcludeCourseID is null or CourseID !=@ExcludeCourseID)
                     and CourseCode=@CourseCode 
                     and IsActive=1
                     )
                begin
                  Set @ErrorMessage =FORMATMESSAGE('There is An Active Course With CODE: %s',@CourseCode);
                  Throw 50001,@ErrorMessage,1;
                end
End;
go

create or alter procedure usp_ChangeCourseActiveStatus
                               @CourseID int,
                               @NewCourseActiveStatus bit,
                               @ChangedByUserID int  --For Logging Latter
As
Begin
        declare @ErrorMessage nvarchar(max);

        if not exists (Select 1 from Courses where CourseID=@CourseID)
             Begin
                 Set @ErrorMessage=FORMATMESSAGE('There is No Course in The System with ID %d',@CourseID);
                 Throw 50001,@ErrorMessage,1;
             End;
        Declare @CurrentActiveStatus bit=(Select IsActive from Courses where CourseID=@CourseID);

        if @NewCourseActiveStatus=@CurrentActiveStatus
                return;
        
        if @CurrentActiveStatus=0 and @NewCourseActiveStatus =1
             Begin

                  declare @CourseCode nvarchar(50)=(Select CourseCode from Courses where CourseID=@CourseID );
                  exec usp_CheckActiveCourseWithCode
                           @CourseCode=@CourseCode;
             End;
        Update Courses
        Set IsActive=@NewCourseActiveStatus
        where CourseID=@CourseID;

        Select @@ROWCOUNT as RowsEffected;
End;
go


create or alter procedure usp_UpdateCourseInfoByCourseID
                          @CourseID int,
                          @CourseName nvarchar(50),
                          @CourseCode nvarchar(50),
                          @Description nvarchar(max),
                          @Credit decimal(4,2),
                          @DepartmentID int
As
Begin 
       Set nocount ON;
          exec usp_CheckActiveCourseWithCode
                 @CourseCode=@CourseCode,
                 @ExcludeCourseID=@CourseID;
       update Courses 
       Set    CourseName=@CourseName,
              CourseCode=@CourseCode,
              Description=@Description,
              Credit=@Credit,
              DepartmentID=@DepartmentID
       where CourseID=@CourseID
              and    IsActive=1;


       Select @@ROWCOUNT as RowsEffected;
End;
go

--               4-D E L E T E

create or alter procedure usp_DeleteCourseInfoByCourseID
                          @CourseID int
As
Begin 
       Set nocount ON;

       update Courses 
       Set   
              IsActive=0
       where CourseID=@CourseID
       and    IsActive=1;

       Select @@ROWCOUNT as RowsEffected;
End;
   
go

create or alter Trigger trg_SoftDeleteCourseInfoByCourseID
On Courses 
Instead of delete
As
Begin 
       Set nocount ON;

       update C
       Set   
              C.IsActive=0
       From Courses C
       Inner Join Deleted D
       On C.CourseID=D.CourseID
       and    C.IsActive=1;

       
End;
   

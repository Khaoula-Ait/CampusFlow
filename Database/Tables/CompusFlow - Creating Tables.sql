use  CampusFlow_Try;

go
Create  Table Settings
(SettingsID int,
MinimumAllowedAgeForStudents smallInt not null,
MinimumAllowedAgeForInstructors smallInt not null,
constraint PK_Settings Primary key(SettingsID) ,
constraint chk_OneSettingsRow check (SettingsID=1)
)

go
insert into Settings (settingsID,MinimumAllowedAgeForStudents,MinimumAllowedAgeForInstructors)
values(1,16,19)


go

create Table People
(PersonID int Identity(1,1),
NationalNumber nvarchar(18)not null,
FirstName nvarchar(50) not null,
SecondName nvarChar(50) ,
LastName nvarchar(50) not null,
Gender bit not  null,--0Male 1Female
DateOfBirth Date not null,--different checks for different type of poeple SP
Email nvarchar(50) not null,
Address nvarchar(100) not null,
ImagePath nvarchar(Max) null,
constraint UC_Email unique(Email),
constraint UC_NationalNumber unique(NationalNumber),
constraint chk_CheckValidNationalNumber check(NationalNumber like replicate('[0-9]',18)),
constraint PK_People primary key(PersonID)
)


go 

create table Users
(UserID int identity(1,1),
PersonID int not null,
UserName nvarchar(100) not null,
PasswordHash VarBinary(32) not null,
Salt varBinary(16) not null,
Iterations int not null,
Role tinyint not null 
constraint df_UserRole default 1,--admin
FailedLoginAttempts tinyint not null
constraint df_FailedLoginAttempts default 0,
IsActive bit not null
constraint df_IsUserActive default 1,
IsLocked bit not null
constraint df_IsUserLocked default 0,
CreatedByUserID int null,
CreationDate DateTime2(0) not null
constraint df_UserCreationDate default getDate(),
constraint FK_Users_Users foreign key(CreatedByUserID)references Users(UserID),
constraint chk_ValidUserNameLength check(len(UserName)>3),--i can add later complex logic as Sp Of BLL Meth
constraint chk_ValidPasswordHashLength check(len(PasswordHash)=32),--Hash is 32 Bytes
constraint chk_ValidIterations check(Iterations>=0),
constraint chk_ValidFailedLoginAttempts check(FailedLoginAttempts>=0),
constraint UC_Salt unique(Salt),
constraint UC_UserName unique(UserName) ,
constraint UC_UserPersonID unique(PersonID),
constraint FK_Users_People Foreign key(PersonID)references People(PersonID),
constraint PK_Users Primary key(UserID)
)

go

create table GradesScale
(
GradeScaleID int Identity(1,1),
MinScore decimal(5,2) not null,
MaxScore Decimal(5,2)Not null,
GradeLetter varchar(2) not null,
GPAPoint decimal(3,2) not null,
IsActive bit not null
constraint df_IsGradeScaleActive default 1,
CreatedByUserID int not null,
CreationDate DateTime2(0) not null
constraint df_GradesScaleCreationDate default getDate(),
constraint FK_GradeScales_Users foreign key(CreatedByUserID)references Users(UserID),
constraint chk_PositiveGPA check(GPAPoint>=0 and GPAPoint<=4),
constraint chk_NonEmptyGradeLetter check(len(Trim(GradeLetter))>0),
constraint chk_VAlidScoreRange check(MinScore>=0 and MaxScore<=100and MaxScore>=MinScore ),
constraint PK_GradeScale Primary key(GradeScaleID)
)
go
-- i will check the uniquness of the range using an Sp
go
create  unique nonclustered  index Idx_UniqueActiveGradeLetter
On GradesScale(GradeLetter)
where IsActive=1;
go
create  unique nonclustered  index Idx_UniqueActiveGPAPoint
On GradesScale(GPAPoint)
where IsActive=1;
go

alter table settings 
add EnrollmentDays tinyint not null
constraint df_EnrollmentDays default 15;
go
Create table Semesters
(SemesterID int identity(1,1),
Name nvarchar(50) not null,--should that be unique??
Description nvarchar(Max) ,
SemesterStartDate DateTime2(0) not null,
SemesterEndDate DateTime2(0) Not null,
SemesterActualEndDate DateTime2(0) null,
EnrollmentStartDate DateTime2(0) not null,--Student enrollment in University not courses??
EnrollmentEndDate DateTime2(0) not null,--calculated from EnrollmentDays in Settings table
Status tinyint not null,--0Upcoming 1 Active 2 Completed
IsActive bit not null,
CreatedByUserID int not null,
CreationDate DateTime2(0) not null
constraint df_SemesterCreationDate default SysDateTime(),
constraint FK_Semesters_Users foreign key(CreatedByUserID)references Users(UserID),
constraint chk_NonEmptySemesterName check(len(trim(Name))>0),
constraint chk_ValidSemesterStatus check(Status in(0,1,2)),
constraint chk_ValidSemesterEndDate check(SemesterEndDate>SemesterStartDate),
constraint chk_ValidSemesterActualEndDate check(SemesterActualEndDate is null or SemesterActualEndDate>SemesterStartDate ),
constraint chk_ValidEnrollmentStartDate check(EnrollmentStartDate<=SemesterStartDate),
constraint chk_ValidEnrollmentEndDate check(EnrollmentEndDate>EnrollmentStartDate and EnrollmentEndDate<SemesterEndDate and (SemesterActualEndDate is null or EnrollmentEndDate <SemesterActualEndDate)),
constraint PK_Semesters primary key(SemesterID)
);
go
create unique nonclustered index Idx_UniqueActiveSemeterName
on Semesters(Name)
where IsActive=1;
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


create table Instructors 
(InstructorID int identity(1,1),
PersonID int not null,
DepartmentID int not null,
HireDate Date not null
constraint df_InsructorHireDate default GetDate(),
Title tinyint not null
constraint df_InstructorTitle default 1, --1 Instructor --2 for Asociate --3 for Adjunct
MaxNumberOfSectionsPerSemester tinyint not null
constraint df_InstructorMaxNumberOfSectionsPerSemester default 5,
IsActive bit not null default 1,
CreatedByUserID int not null,
CreationDate DateTime2(0) not null
constraint df_InstructorCreationDate default SysDateTime(),
constraint FK_Instructors_Users foreign key(CreatedByUserID)references Users(UserID),
constraint chk_ValidMaxNumberOfSectionsPerSemester checK(MaxNumberOfSectionsPerSemester>=0),
constraint chk_ValidTitle check(Title in (1,2,3)),
constraint chk_ValidHireDate check(HireDate<=GetDate()),
Constraint FK_Instructors_Departments foreign key(DepartmentID) references Departments(DepartmentID),
constraint FK_Instructors_People Foreign key(PersonID)References People(PersonID),
constraint UC_InstructorPersonID unique(PersonID),
constraint PK_Instructors Primary key(InstructorID)
)


go 

Alter table Departments 
Add Constraint FK_HeadOfDepartment_Instructors foreign key(HeadOfDepartmentID) references Instructors(InstructorID)

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

Create  table Students
(
StudentID int identity(1,1),
PersonID int not null,
MajorDepartmentID int not null,
UniversityEnrollmentDate Date  not null
constraint df_EnrolmentDate default getdate(),
AcademicStatus tinyint not null --1Good 0 Probation 2 Suspended
constraint df_AcademicStatus default(1),
StudentStatus tinyint not null --1 Active 0 Inactive 2 Withdrawn 3 Graduated
constraint df_StudentStatus default(1),
CreatedByUserID int not null,
CreationDate DateTime2(0) not null
constraint df_StudentCreationDate default SysDateTime(),
constraint FK_Students_Users foreign key(CreatedByUserID)references Users(UserID),
constraint chk_ValidEnrollmentDate check (UniversityEnrollmentDate<=GetDate()),
constraint chk_ValidStudentStatus check (StudentStatus in (0,1,2,3)),
constraint chk_ValidAcademicStatus check (AcademicStatus in (0,1,2)),
constraint UC_StudentPersonID unique(PersonID),
constraint FK_Students_MajorDepartments Foreign key(MajorDepartmentID)References Departments(DepartmentID),
Constraint FK_Students_People Foreign key(PersonID)references People(PersonID),
constraint PK_Students Primary key(StudentID)
)

go

create table Enrollments
(EnrollmentID int identity(1,1),
StudentID int not null,
CourseSectionID int not null,
EnrollmentStartDate DateTime2(0) not null
constraint df_StudentEnrolmentInCourseSectionStartDate default SysDateTime(),
EnrollmentActualEndDate DateTime2(0) null,--can be less greater or equal to SemesterEndDate
GradeLetter varchar(2) null,
GPAPoint decimal(3,2)  null,
Score Decimal(5,2) null,
EnrollmentStatus tinyint not null,--0 Dropped 1Enrolled  2completed
DropDate Date null,
CreatedByUserID int not null,
CreationDate DateTime not null
constraint df_EnrollmentCreationDate default getDate(),
constraint FK_Enrollments_Users foreign key(CreatedByUserID)references Users(UserID),
constraint chk_EnrollmentStatus check(EnrollmentStatus in (0,1,2)),
constraint chk_PositiveEnrollmentGPA check(GPAPoint is null or GPAPoint>=0.0),
constraint chk_PositiveScore check(Score is null or Score>=0.0),
constraint chk_ValidEnrollmentStartEndDate check(EnrollmentActualEndDate is null or EnrollmentActualEndDate>EnrollmentStartDate),--later i add logic to check that it is within the EnrolmentSD and ED in semester Table
constraint chk_ValidDropDate check(DropDate is null or (EnrollmentActualEndDate is Null and  DropDate>=EnrollmentStartDate)),
constraint FK_Enrollments_CourseSections Foreign key(CourseSectionID)references CourseSections(CourseSectionID),
Constraint FK_Enrollments_Students foreign key(StudentID)references Students(StudentID),
constraint PK_Enrollments primary key(EnrollmentID)
)

go
create unique nonClustered index Idx_UniqueNonDropedEnrollmenForStudentAndCourseSection
on Enrollments(CourseSectionID,StudentID)
where EnrollmentStatus in (1,2)

use CampusFlow_Try;
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

--          C    R    U    D

--                   1-C R E A T E
create or alter procedure usp_AddNewStudent
                         @PersonID int,
                         @MajorDepartmentID int,
                         @UniversityEnrollmentDate date= null,
                         @AcademicStatus tinyint =1,
                         @StudentStatus tinyint =1,
                         @CreatedByUserID int ,
                         @CreationDate DateTime2(0) =null,
                         @NewStudentID int output
As
Begin 

      Set NoCount On;
      insert into Students(PersonID,MajorDepartmentID,UniversityEnrollmentDate,AcademicStatus,StudentStatus,CreatedByUserID,CreationDate)
      values(@PersonID,@MajorDepartmentID,IsNull(@UniversityEnrollmentDate,GetDate()),@AcademicStatus,@StudentStatus,@CreatedByUserID,IsNull(@CreationDate,SysDateTime()));

      Set @NewStudentID =SCOPE_IDENTITY();
End;
go


--                   2-R E A D
create or alter procedure usp_GetStudentInfoByStudentID
                            @StudentID int
As
Begin 
      
      Set Nocount on;

      select  StudentID,
              PersonID,
              MajorDepartmentID,
              UniversityEnrollmentDate,
              AcademicStatus,
              StudentStatus,
              CreatedByUserID,
              CreationDate
      from Students
      where StudentID=@StudentID;
End;
go

create or alter procedure usp_GetStudentInfoByPersonID
                            @PersonID int
As
Begin 
      
      Set Nocount on;

      select  StudentID,
              PersonID,
              MajorDepartmentID,
              UniversityEnrollmentDate,
              AcademicStatus,
              StudentStatus,
              CreatedByUserID,
              CreationDate
      from Students
      where PersonID=@PersonID;
End;
go

create or alter procedure usp_GetAllStudents
                            @MajorDepartmentID int =null,
                            @AcademicStatus tinyint =null,
                            @StudentStatus tinyint =null,
                            @CreatedByUserID int=null,
                            @EnrolledInUniversityAfterDate Date =null,
                            @EnrolledInUniversityBeforeDate Date=null

As
Begin 
      
      Set Nocount on;

      select  StudentID,
              PersonID,
              MajorDepartmentID,
              UniversityEnrollmentDate,
              AcademicStatus,
              StudentStatus,
              CreatedByUserID,
              CreationDate
      from Students
      where (@MajorDepartmentID is null or MajorDepartmentID=@MajorDepartmentID)
      And   (@AcademicStatus is null or AcademicStatus=@AcademicStatus)
      And   (@StudentStatus is null or StudentStatus=@StudentStatus)
      And   (@CreatedByUserID is null or CreatedByUserID=@CreatedByUserID)
      And   (@EnrolledInUniversityAfterDate is null or UniversityEnrollmentDate>=@EnrolledInUniversityAfterDate)
      And   (@EnrolledInUniversityBeforeDate is null or UniversityEnrollmentDate<=@EnrolledInUniversityBeforeDate);
End;
go

--              3-U P D A T E

create or alter procedure usp_ChangeStudentMajorDepartment
                                @StudentID int,
                                @CurrentDepartmentID int,--for logging
                                @NewDepartmentID int
As
Begin 

      Set Nocount on;
      update Students
      Set MajorDepartmentID=@NewDepartmentID
      where StudentID=@StudentID
      And   MajorDepartmentID=@CurrentDepartmentID
      And   StudentStatus =1  --Active 
      select @@ROWCOUNT as RowsEffected;
End;
go

create or alter procedure usp_ChangeStudentAcademicStatus
                                  @StudentID  int,
                                  @NewAcademicStatus tinyint
As
Begin 

   Set Nocount on;

   update Students
   Set AcademicStatus=@NewAcademicStatus
   where StudentID=@StudentID          
   And   StudentStatus=1;
   
   select @@ROWCOUNT as RowsEffected;
End;


go

create or alter procedure usp_ChangeStudentStatus 
                            @StudentID int,
                            @NewStudentStatus tinyint
As
Begin 
      Set Nocount on;

      update Students
      Set StudentStatus=@NewStudentStatus
      where StudentID=@StudentID
      And   (
              StudentStatus=1
      Or     (StudentStatus in(0,2,3) and @NewStudentStatus=1)
             )

      Select @@ROWCOUNT as RowsEffected;

End;
go

--       4-D E L E T E

create or alter procedure usp_DeleteStudent
                             @StudentID int
As
Begin
    Set nocount on;

    update Students
    Set StudentStatus=0
    where StudentID=@StudentID
    And   StudentStatus=1;

    select @@ROWCOUNT as RowsEffected;
End;
go

create or alter trigger trg_SoftDeleteStudent
On Students
Instead of delete
As
Begin 
       Set Nocount on;

       update S
       Set S.StudentStatus=0
       From Students S
       Inner join Deleted D
       on S.StudentID=D.StudentID
       where S.StudentStatus=1;
End;



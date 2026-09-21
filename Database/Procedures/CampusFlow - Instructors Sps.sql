use CampusFlow_Try;
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
--                     C   R   U   D

--              1-C R E A T E



create or alter procedure usp_AddNewInstructor
                           @PersonID int,
                           @DepartmentID int,
                           @HireDate Date =null,
                           @Title tinyint =1,
                           @MaxNumberOfSectionsPerSemester tinyint =5,
                           @IsActive bit =1,
                           @CreatedByUserID int,
                           @CreationDate datetime2(0) =null,
                           @NewInstructorID int output
As
Begin
      Set NOCOUNT ON;
      insert into Instructors(PersonID,DepartmentID,HireDate,Title,MaxNumberOfSectionsPerSemester,IsActive,CreatedByUserID,CreationDate)
      values(@PersonID,@DepartmentID,IsNull(@HireDate,Getdate()),@Title,@MaxNumberOfSectionsPerSemester,@IsActive,@CreatedByUserID,IsNull(@CreationDate,SysDateTime()));

      select @NewInstructorID=SCOPE_IDENTITY();

End;
go


--          2-R E A D
create or alter procedure usp_GetInstructorInfoByInstructorID
                           @InstructorID int
As
begin 
      Set NOCOUNT ON;

      select InstructorID,
             PersonID,
             DepartmentID,
             Title,
             HireDate,
             MaxNumberOfSectionsPerSemester,
             IsActive,
             CreatedByUserID,
             CreationDate
      from Instructors
      where InstructorID=@InstructorID
end;

go
create or alter procedure usp_GetInstructorInfoByPersonID
                           @PersonID int
As
begin 
      Set NOCOUNT ON;

      select InstructorID,
             PersonID,
             DepartmentID,
             Title,
             HireDate,
             MaxNumberOfSectionsPerSemester,
             IsActive,
             CreatedByUserID,
             CreationDate
      from Instructors
      where PersonID=@PersonID
end;

go
create or alter procedure usp_GetAllInstructors
                           @DepartmentID int= null,
                           @Title tinyint= null,
                           @HiredAfterDate date =null,
                           @HiredBeforeDate date =null,
                           @CreatedByUserID int =null
As
begin 
      Set NOCOUNT ON;

      select InstructorID,
             PersonID,
             DepartmentID,
             Title,
             HireDate,
             MaxNumberOfSectionsPerSemester,
             IsActive,
             CreatedByUserID,
             CreationDate
      from Instructors
      where (@DepartmentID is null or DepartmentID=@DepartmentID)
      And   (@Title is null or Title=@Title)
      And   (@HiredAfterDate is null or HireDate>=@HiredAfterDate)
      And   (@HiredBeforeDate is null or HireDate<=@HiredBeforeDate)
      And   (@CreatedByUserID is null or CreatedByUserID=@CreatedByUserID)

end;

go
create or alter procedure usp_GetInstructorMaxNumberOfSectionsPerSemester
                           @InstructorID int
As
begin 
      Set NOCOUNT ON;

      select 
             MaxNumberOfSectionsPerSemester
             
      from Instructors
      where InstructorID=@InstructorID
      and   IsActive=1;
end;
go 


--               3-U P D A T E

create or alter procedure usp_UpdateInstructorInfoByInstructorID
                       @InstructorID int,
                       @DepartmentID int,
                       @Title tinyint,
                       @HireDate Date,
                       @MaxNumberOfSectionsPerSemester tinyint,
                       @IsActive bit
As
Begin

     Set NOCOUNT ON;
     if not exists(select 1 from Instructors where InstructorID=@InstructorID and IsActive=1)
        Begin
             Select 0 as RowsEffected;
             return;
        End;

     declare @InstructorIsHeadOfDepartmentID int=(
                                        select DepartmentID 
                                        From Departments 
                                        where HeadOfDepartmentID=@InstructorID
                                        and   IsActive=1
                                        );
     -- if i change the instructor is the head and am changing its department
     -- so i drop the head of the department is heading becuase they are
     --no loger working then
     -- and also if am decativating the account

     if @InstructorIsHeadOfDepartmentID is not null and( @DepartmentID !=@InstructorIsHeadOfDepartmentID or  @IsActive=0)
            Begin
            exec usp_ChangeDepartmentHead
                       @DepartmentID=@InstructorIsHeadOfDepartmentID,
                       @NewHeadOfDepartmentID=null;
            End; 

     update Instructors
     Set    --PersonID=@PersonID, i took that off because 
     --it is wierd/wrong in my opinion that the system change actuall person info
            DepartmentID=@DepartmentID,
            Title=@Title,
            HireDate=@HireDate,
            MaxNumberOfSectionsPerSemester=@MaxNumberOfSectionsPerSemester,
            IsActive=@IsActive
     where InstructorID=@InstructorID
     and IsActive=1;

    
     select @@ROWCOUNT as RowsEffected;
End;
go

create or alter procedure usp_UpdateInstructorInfoByPersonID
                       @PersonID int,
                       @DepartmentID int,
                       @Title tinyint,
                       @HireDate Date,
                       @MaxNumberOfSectionsPerSemester tinyint,
                       @IsActive bit
As
Begin

     Set NOCOUNT ON;
        

      declare @InstructorID int =(select InstructorID from Instructors where PersonID=@PersonID and IsActive=1);
           
          if @InstructorID  is null
               Begin
                   Select 0 as RowsEffected;
                   return;
               End;
      exec usp_UpdateInstructorInfoByInstructorID
                        @InstructorID=@InstructorID,
                        @DepartmentID=@DepartmentID,
                        @Title=@Title,
                        @HireDate=@HireDate,
                        @MaxNumberOfSectionsPerSemester=@MaxNumberOfSectionsPerSemester,
                        @IsActive=@IsActive;
    
     
End;
go




--               4-D E L E T E

create or alter procedure usp_DeleteInstructorByInstructorID
                       @InstructorID int
As
Begin

     Set NOCOUNT ON;

     declare @DepartmentID int=(Select DepartmentID
                                From Departments D 
                                where HeadOfDepartmentID=@InstructorID
                                And   IsActive=1
                                );

  
    if @DepartmentID is not null 
          exec usp_ChangeDepartmentHead
                   @DepartmentID=@DepartmentID,
                   @NewHeadOfDepartmentID=null;

     update Instructors
     Set   
            IsActive=0
     where InstructorID=@InstructorID
     and IsActive=1;

     

     select @@ROWCOUNT as RowsEffected;
End;
go

create or alter procedure usp_DeleteInstructorByPersonID
                       @PersonID int
As
Begin

     Set NOCOUNT ON;
     declare @InstructorID int=(Select InstructorID from Instructors where PersonID=@PersonID and isActive=1);
     
         
          if @InstructorID  is null
               Begin
                   Select 0 as RowsEffected;
                   return;
               End;

     exec usp_DeleteInstructorByInstructorID
                     @InstructorID=@InstructorID;
End;
go


create or alter  Trigger trg_SoftDeleteInstructor
On Instructors
instead of Delete
As
Begin

     Set NOCOUNT ON;
     
     declare @DepratmentsID dbo.IDsList;

     insert into @DepratmentsID(ID)
     select Dep.DepartmentID
     from deleted D
     inner join Departments Dep
     On D.InstructorID=Dep.HeadOfDepartmentID
     where D.IsActive=1
     and   Dep.IsActive=1;

     update I
     Set  I.IsActive=0
     From Instructors I
     inner join deleted D
     On I.InstructorID=D.InstructorID
     and I.IsActive=1;

    exec usp_DropDepartmentsHead
               @DepartmentsID=@DepratmentsID ;
    
End;

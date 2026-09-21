use CampusFlow_Try;
go 

--                  C R U D


---           1-C R E A T E
go
create or alter Procedure usp_AddNewUser
                @PersonID int,
                @UserName nvarchar(100),
                @PasswordHash VarBinary(32),
                @Salt VarBinary(16),
                @Role tinyint=1 ,
                @FailedLoginAttempts tinyint=0,
                @IsActive bit=1,
                @IsLocked bit=0,
                @CreatedByUserID int ,
                @CreationDate DateTime =null,
                @Iterations int=100000,
                @NewUserID int output
As
Begin
Set Nocount on;
insert into Users(PersonID,UserName,PasswordHash,Salt,Iterations,Role,FailedLoginAttempts,IsActive,IsLocked,CreatedByUserID,CreationDate)
values(@PersonID,@UserName,@PasswordHash,@Salt,@Iterations,@Role,@FailedLoginAttempts,@IsActive,@IsLocked,@CreatedByUserID,IsNull(@CreationDate,GetDate()));
Select @NewUserID=SCOPE_IDENTITY();

End;

go

--            2-R E A D


create or alter Procedure usp_GetUserByUserID 
                     @UserID int
As
Begin
Set Nocount on;
    select UserID,
           PersonID,
           UserName,
           PasswordHash,
           Salt,
           Iterations,
           Role,
           FailedLoginAttempts,
           IsActive,
           IsLocked,
           CreatedByUserID,
           CreationDate
    from Users
    where UserID=@UserID;
End;

go
create or alter Procedure usp_GetUserByPersonID 
                     @PersonID int
As
Begin
Set Nocount on;
    select UserID,
           PersonID,
           UserName,
           PasswordHash,
           Salt,
           Iterations,
           Role,
           FailedLoginAttempts,
           IsActive,
           IsLocked,
           CreatedByUserID,
           CreationDate
    from Users
    where PersonID=@PersonID;
End;
go

--this used for login 
create or alter Procedure usp_GetUserByUserName
                      @UserName nvarchar(100)
As
Begin
Set Nocount on;
    select
           UserID,
           PersonID,
           UserName,
           PasswordHash,
           Salt,
           Iterations,
           Role,
           FailedLoginAttempts,
           IsActive,
           IsLocked,
           CreatedByUserID,
           CreationDate
    from Users
    where UserName=@UserName;
End;

go
--after i verify password i populate the currentUser and open the Main Form 

--filter
create or alter procedure usp_GetAllUsers
                            @UserName nvarchar(100)=null, 
                            @Role tinyint =null,
                            @FailedLoginAttempts tinyint =null,
                            @IsActive bit=null,
                            @IsLocked bit =null,
                            @CreatedByUserID int=null,
                            @CreationDate Datetime2(0) =null,
                            @FilterByNoCreator bit=1--Dont care about CreatedByUserID
As
Begin
Set Nocount on;

    select UserID,
           PersonID,
           UserName,
           PasswordHash,
           Salt,
           Iterations,
           Role,
           FailedLoginAttempts,
           IsActive,
           IsLocked,
           CreatedByUserID,
           CreationDate
    from Users
    where  (@UserName is null or UserName like '%'+@UserName+'%')
    And    (@Role     is null or Role=@Role)
    And    (@FailedLoginAttempts is null or FailedLoginAttempts=@FailedLoginAttempts)
    And    (@IsActive is null or IsActive=@IsActive)
    And    (@IsLocked is null or IsLocked=@IsLocked)
    And    (     @FilterByNoCreator=1
               or
                 (CreatedByUserID is null and @CreatedByUserID is null)
               or
                 (CreatedbyUserID=@CreatedByUserID)
            )
    And    (@CreationDate is null or( @CreationDate>=DATEFROMPARTS(Year(CreationDate),Month(CreationDate),Day(CreationDate))
                                      and
                                      @CreationDate<DATEFROMPARTS(Year(CreationDate),Month(CreationDate),Day(CreationDate)+1)
                                     )
           );
End;
go
--there is case for CreatedByUserID=null 
--so the result will always include the first user 
--how can diffrentiate two cases
    

--            3-U P D A T E

--in my opinion all user columns are business column so i decided to handle there Update/change sepretly
--and with personID i think it is not logical to change basetype mid way
--what do u think??

create or alter procedure usp_ChangeUserName
                      @UserID int,
                      @CurrentUserName nvarchar(100),--for logging
                      @NewUserName nvarchar(100),
                      @UserChangingID int--current system userID i will use it latter for loggin
                      --provide better naming if for @UserChangingID if it is not clrar
As
Begin 
         Set nocount on;
         Update Users
         Set  
              UserName=@NewUserName
             
         where UserID=@UserID
         And   IsActive=1
         And   IsLocked=0;

         select @@ROWCOUNT as RowsEffected;
End

go

create or alter procedure usp_ChangeUserPassword
                      @UserID int,
                      @CurrentPasswordHash varbinary(32),--For logging later
                      @CurremtSalt varBinary(16),
                      @CurrentIterations int=100000,
                      @NewPasswordHash VarBinary(32),
                      @NewSalt Varbinary(16),
                      @NewIterations int=100000,
                      @UserChangingID int--current system userID i will use it latter for loggin
As
Begin 
         Set nocount on;
         Update Users
         Set  
              PasswordHash=@NewPasswordHash,
              Salt=@NewSalt,
              Iterations=@NewIterations
         where UserID=@UserID
         And   IsActive=1
         And   IsLocked=0;

         select @@ROWCOUNT as RowsEffected;
End

go

create or alter procedure usp_ChangeUserRole
                      @UserID int,
                      @CurrentRole tinyint,--For logging
                      @NewRole tinyint,
                      @UserChangingID int--current system userID i will use it latter for loggin
As
Begin 
         Set nocount on;
         Update Users
         Set  
              Role=@NewRole
         where UserID=@UserID
         And   IsActive=1
         And   IsLocked=0;

         select @@ROWCOUNT as RowsEffected;
End


go

create or alter procedure usp_ChangeUserFailedLogginAttempts
                      @UserID int,
                      @NewFailedLoggingAttempts tinyint,
                      @UserChangingID int--current system userID i will use it latter for loggin
As
Begin 
         Set nocount on;
         Update Users
         Set  
             FailedLoginAttempts=@NewFailedLoggingAttempts
         where UserID=@UserID
         And   IsActive=1
         And   IsLocked=0;

         select @@ROWCOUNT as RowsEffected;
End

go

create or alter procedure usp_ChangeUserActiveStatus
                      @UserID int,
                      @CurrentActiveStatus bit,--For logging later
                      @NewActiveStatus bit,
                      @UserChangingID int--current system userID i will use it latter for loggin
As
Begin 
         Set nocount on;
         Update Users
         Set  
              IsActive=@NewActiveStatus
         where UserID=@UserID;

         select @@ROWCOUNT as RowsEffected;
End

go

go

create or alter procedure usp_ChangeUserLockedStatus
                      @UserID int,
                      @CurrentLockedStatus bit,--For logging later
                      @NewLockedStatus bit,
                      @UserChangingID int--current system userID i will use it latter for loggin
As
Begin 
        Set nocount on;
         Update Users
         Set IsLocked=@NewLockedStatus
         where UserID=@UserID
         And   IsActive=1;

         select @@ROWCOUNT as RowsEffected;
End



go

--            4-D E L E T E 

create or alter Procedure usp_DeleteUserByUserID
                           @UserID int
As
 Begin
         set nocount on;
         update Users
         Set IsActive=0
         where UserID=@UserID
         and  IsActive=1;
end;
go
create or alter trigger trg_SoftDeleteUsers
On Users
instead of delete                          
As
Begin 
       set nocount on;
       update U
       Set U.IsActive=0
       from Users U
       inner  join deleted D
       On U.UserID=D.UserID
       where U.IsActive=1
end;

--sense logging triggers need tables i will add them later
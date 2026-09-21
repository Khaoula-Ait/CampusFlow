use CampusFlow_Try;
go
--                         CRUD

--                         CREATE
go
create or alter Procedure usp_AddNewPerson
           @NationalNumber nvarchar(18),
           @FirstName nvarchar(50),
           @SecondName nvarchar(50)= null,
           @LastName nvarchar(50) ,
           @Gender bit,
           @DateOfBirth Date,
           @Email nvarchar(50),
           @Address nvarchar(100),
           @ImagePath nvarchar(max)=null,
           @NewPersonID int output
As
Begin
    Set Nocount on;
    insert into People(NationalNumber,FirstName,SecondName,LastName,Gender,DateOfBirth,Email,Address,ImagePath)
    values(@NationalNumber,@FirstName,@SecondName,@LastName,@Gender,@DateOfBirth,@Email,@Address,@ImagePath);
    Select @NewPersonID=SCOPE_IDENTITY();
end


--                   READ

go
create or alter procedure usp_GetPersonByPersonID
              @PersonID int
As
Begin
    Set  nocount on;
    select PersonID,NationalNumber,FirstName,SecondName,LastName,Gender,Email,DateOfBirth,Address,ImagePath
    From People
    where PersonID=@PersonID;
         
end
 
go
create or alter procedure usp_GetPersonByNationalNumber
              @NationalNumber nvarchar(18)
As
Begin
    Set  nocount on;
    select PersonID,NationalNumber,FirstName,SecondName,LastName,Gender,Email,DateOfBirth,Address,ImagePath
    From People
    where NationalNumber=@NationalNumber;
         
end
go
--get people with optional filters

create or alter procedure usp_GetAllPeople
                @FirstName nvarchar(50)=null,
                @LastName nvarchar(50) =null,
                @Gender bit=null,
                @Email nvarchar(50)=null,
                @Address nvarchar(100)=null
As
begin
       Set Nocount on;
       Select PersonID,NationalNumber,FirstName,SecondName,LastName,Gender,DateOfBirth,Email,Address,ImagePath
       from People
       where 
               (  @FirstName is null or FirstName like '%'+ @FirstName + '%')
            and(  @LastName  is null or LastName  like '%'+ @LastName  + '%')
            and(  @Gender    is null or Gender     = @Gender                )
            and(  @Email     is null or Email     like '%'+ @Email     + '%')
            and(  @Address   is null or Address   like '%'+@Address    + '%');
End;


go

--                 Update

create or alter Procedure usp_UpdatePersonInfo
               @PersonID int,
               @NationalNumber nvarchar(18),
               @FirstName nvarchar(50),
               @SecondName nvarchar(50)=null,
               @LastName nvarchar(50) ,
               @Gender bit,
               @DateOfBirth Date,
               @Email nvarchar(50),
               @Address nvarchar(100),
               @ImagePath nvarchar(Max)=null
As
begin 
   Set Nocount on;
   update People 
   Set  NationalNumber=@NationalNumber,
        FirstName=@FirstName,
        SecondName=@SecondName,
        LastName=@LastName,
        Gender=@Gender,
        DateOfBirth=@DateOfBirth,
        Email=@Email,
        Address=@Address,
        ImagePath=@ImagePath
   where PersonID=@PersonID;
   select @@ROWCOUNT as RowsEffected;
end;

--                      DELETE

go
create or alter procedure usp_DeletePersonByPersonID
                     @PersonID int
As
Begin 
   set nocount on;

   Delete From People
   where PersonID=@PersonID;
   select @@ROWCOUNT as RowsEffected;
End;

go

create or alter procedure usp_DeletePersonByNationalNumber
                     @NationalNumber nvarchar(18)
As
Begin 
   set nocount on;

   Delete From People
   where NationalNumber=@NationalNumber;

   select @@ROWCOUNT as RowsEffected;
End;
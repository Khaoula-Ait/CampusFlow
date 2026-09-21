use CampusFlow_Try;
insert into People(FirstName,LastName,DateOfBirth,Email,Address)
values('Khaoula','Ait','2002-09-01','akaoula34@gmail.com','Alg')
go

insert into users(PersonID,UserName,PasswordHash,Salt,IsActive,IsLocked)
values(1,'Kay1',
convert(varBinary(32),'4CFA3C3DDC25DB2464CFB676C74B3421A7EC6BFD2F21B4D5EA767B4DAB12994B',2),
convert(varbinary(16),'21B37863A183084516058795C2F50183',2),1,0)

select * from Users

--I Used Pbkdf2 Algorithm instead of using SHA_256 directly
--it can use SHA_256 as it underlying Hash Function
--and adds a Salt and many iterations to make password guessing more expensive

--salt  Hash both as byte[] so i convert them to hexadecimal
--copy past here
--convert(...,2) 2 tell the SQL Server this string is Hexadecimal without ox
--this function then convert string into binary :)

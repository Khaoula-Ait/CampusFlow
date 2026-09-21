use CampusFlow_Try
insert into GradesScale(MinScore,MaxScore,GradeLetter,GPAPoint,CreatedByUserID)
values(00.0,59.99,'F',0.0,1),
(60.0,69.99,'D',1.0,1),
(70.0,79.99,'C',2.0,1),
(80.0,89.99,'B',3.0,1),
(90.0,100,'A',4.0,1);

select * from GradesScale

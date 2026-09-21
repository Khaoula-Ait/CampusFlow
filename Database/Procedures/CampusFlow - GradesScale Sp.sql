use CampusFlow_Try;
go

create or alter procedure usp_CheckOverlappingScoreRange
                         @MinScore decimal(5,2),
                         @MaxScore decimal(5,2),
                         @IgnoreGradeScaleID int =null,
                         @WithIsActive bit=1,
                         @IsOverLap bit output
As
begin
       Set nocount on;
         declare @ErrorMessage nvarchar(Max);

         if @MaxScore<=@MinScore
             Begin
                 Set @IsOverLap =0;
                 Set @ErrorMessage=FORMATMESSAGE('The Max Score: %s is Less or equal to The Min Score: %s',cast(@MaxScore as nvarchar(10)),Cast(@MinScore as nvarchar(10)));
                 throw 50001,@ErrorMessage,1;
             End;

         declare @OverLapCounter int;
         select @OverLapCounter=Count(*)
         from GradesScale
         where IsActive=@WithIsActive
         and   (@IgnoreGradeScaleID is null or  GradeScaleID !=@IgnoreGradeScaleID)
         and(
                MinScore<=@MaxScore
                And
                MaxScore>=@MinScore
            );
         

         if @OverLapCounter>0
                  Set @IsOverLap=1;
         else
                  Set @IsOverLap=0;
End;

go

--                      C R U D

--                     1-C R E A T E 
create or alter procedure usp_AddNewGradeScale
                @MinScore decimal(5,2),
                @MaxScore decimal(5,2),
                @GradeLetter varchar(2),
                @GPAPoint Decimal(3,2),
                @CreatedByUserID int,
                @CreationDate dateTime2(0) =null,
                @IsActive bit=1,
                @NewGradeScaleID int output
As
Begin 
     Set nocount on;
     declare @IsOverLap bit;
     declare @ErrorMessage nvarchar(Max);

     exec usp_CheckOverlappingScoreRange
                  @MinScore=@MinScore,
                  @MaxScore=@MaxScore,
                  @IsOverLap=@IsOverLap output;
     
     if @IsOverLap=0
         Begin 
              insert into GradesScale(MinScore,MaxScore,GradeLetter,GPAPoint,CreatedByUserID,CreationDate,IsActive)
              values(@MinScore,@MaxScore,@GradeLetter,@GPAPoint,@CreatedByUserID,IsNull(@CreationDate,SysDateTime()),@IsActive);
              Select @NewGradeScaleID =SCOPE_IDENTITY();
         End
      Else
         Begin
         Set @ErrorMessage=FORMATMESSAGE('The Score Range You Entered [%s - %s] OverLaps with An Existing Range in the Datebase',cast(@MinScore as nvarchar(10)),Cast(@MaxScore as nvarchar(10)));
         throw 50002,@ErrorMessage,1;
         End;
End;

go


--                     2-R E A D                   


create or alter procedure usp_GetGradeScaleByGradeScaleID
                         @GradeScaleID int
as
Begin 
     Set nocount on;
     select GradeScaleID,
            MinScore,
            MaxScore,
            GradeLetter,
            GPAPoint,
            CreatedByUserID,
            CreationDate,
            IsActive
     from GradesScale
     where GradeScaleID=@GradeScaleID;

end;
go


create or alter procedure usp_GetGradeScoreByScore 
                             @Score Decimal(5,2)
As
Begin 
       Set nocount on;
         Select GradeScaleID,
                MinScore,
                MaxScore,
                GradeLetter,
                GPAPoint,
                CreatedByUserID,
                CreationDate,
                IsActive
         from GradesScale
         where @Score between MinScore and MaxScore
         And   IsActive=1;
End;
go


create or alter procedure usp_GetAllGradesScale
                         @GPAPoint decimal(3,2)=null,
                         @GradeLetter varchar(2)=null,
                         @MinScore decimal(5,2)=null,
                         @MaxScore decimal(5,2)=null,
                         @CreatedByUserID int=null,
                         @IsActive Bit=null
as
Begin 
     Set nocount on;
     select GradeScaleID,
            MinScore,
            MaxScore,
            GradeLetter,
            GPAPoint,
            CreatedByUserID,
            CreationDate,
            IsActive
     from GradesScale
     where (@MinScore is null or( @MinScore<=MinScore))
     And   (@MaxScore is null or (@MaxScore >=MaxScore))
     And   (@GPAPoint is null or @GPAPoint=GPAPoint)
     And   (@GradeLetter is null or @GradeLetter=GradeLetter)
     And   (@CreatedByUserID is null or @CreatedByUserID=CreatedByUserID);
End;
go


--                     3-U P D A T E

 
create or alter Procedure usp_UpdateGradeScaleByGradeScaleID
                                 @GradeScaleID int,
                                 @MinScore decimal(5,2),
                                 @MaxScore decimal(5,2),
                                 @GradeLetter nvarchar(2),
                                 @GPAPoint Decimal(3,2)
As
Begin 
       Set nocount on;
      declare @IsOverLap bit=0;
      declare @ErrorMessage nvarchar(100);

      exec usp_CheckOverlappingScoreRange
                    @MinScore=@MinScore,
                    @MaxScore=@MaxScore,
                    @IgnoreGradeScaleID =@GradeScaleID,
                    @IsOverlap=@IsOverLap output;
                    
      if @IsOverLap =0
           Begin 
                update GradesScale
                set MinScore=@MinScore,
                    MaxScore=@MaxScore,
                    GradeLetter=@GradeLetter,
                    GPAPoint=@GPAPoint
                where GradeScaleID=@GradeScaleID
                And   IsActive=1;
                select @@ROWCOUNT as RowsEffected;

           End
       
       else
           Begin 
           Set @ErrorMessage=FORMATMESSAGE('The Score Range You Entered [%s - %s] OverLaps with An Existing Range in the Datebase',cast(@MinScore as nvarchar(10)),Cast(@MaxScore as nvarchar(10)));
           throw 50002,@ErrorMessage,1;
           End;



end
go
-- changing the Active status require First checking that
--there is no over lap with an active Grade scale 
-- and i also check if the user Enter the same status for the current and new :)
create or alter procedure usp_ChangeGradeScaleActiveStatus
                               @GradeScaleID int,
                               @CurrentActiveStatus bit,--for logging
                               @NewActiveStatus bit,
                               @ChangingUserID int--for logging
As
begin

     Set nocount on;
     
     if @NewActiveStatus=1 and @CurrentActiveStatus=0
         Begin
               declare @MinScore decimal(5,2);
               declare @MaxScore decimal(5,2);
               declare @IsOverlap bit;
               
               declare @ErrorMessage nvarchar(Max);
              
               select @MinScore=MinScore,
                      @MaxScore=MaxScore
               From   GradesScale 
               where GradeScaleID=@GradeScaleID;

               exec usp_CheckOverlappingScoreRange
                          @MinScore=@MinScore,
                          @MaxScore=@MaxScore,
                          @IgnoreGradeScaleID =@GradeScaleID,
                          @IsOverlap=@IsOverlap output;

               if @IsOverlap=1
                   Begin
                       Set @ErrorMessage=FORMATMESSAGE('The Grade Scale With ID %d That You Want to activate , its Range [%s - %s] OverLaps with An Existing Active Range in the Datebase',@GradeScaleID,cast(@MinScore as nvarchar(10)),Cast(@MaxScore as nvarchar(10)));
                       throw 50003,@ErrorMessage,1;
                   End;
         End;--Ends the if no else

if @CurrentActiveStatus=@NewActiveStatus
      return;

      update GradesScale
      Set IsActive=@NewActiveStatus
      where GradeScaleID=@GradeScaleID
      and  IsActive=@CurrentActiveStatus;

      Select @@ROWCOUNT as RowsEffected;
        
End;
go


--  *no instead of trigger for me :(*
-- it cant do what i want i need to enforce permission on table :)
-- for later
-- here i want to capture update this is not my procedures
--how can i do that??
       



--                     4-D E L E T E

create or alter procedure usp_DeleteGradeScaleByGradeScaleID
                              @GradeScaleID int
As
Begin 
       update GradesScale
       Set IsActive=0
       where GradeScaleID=@GradeScaleID
       And IsActive =1;

       Select @@ROWCOUNT as RowsEffected;
End;

go

go
create or alter trigger trg_SoftDeleteGradeScale
on GradesScale
instead of Delete
As
Begin
        update G
        Set G.IsActive=0
        from GradesScale G
        inner join Deleted D
        On G.GradeScaleID=D.GradeScaleID
        where G.IsActive=1;
End;
go

-- After Enrollments


create or alter procedure usp_GetGradeScoreInfoToCalculateGPAByScore 
                             @Score Decimal(5,2),
                             @MinScore decimal(5,2) output,
                             @MinNextScore decimal(5,2)output,
                             @GPAPoint decimal(3,2) output,
                             @GradeLetter varchar(2) output
As
Begin 
       Set nocount on;
         declare @MaxScore decimal(5,2);
         Select
               @MinScore= MinScore,
               @MaxScore=MaxScore,
               @GradeLetter= GradeLetter,
               @GPAPoint= GPAPoint
         from GradesScale
         where @Score between MinScore and MaxScore
         And   IsActive=1;

         select top 1 @MinNextScore=MinScore
         From  GradesScale
         where MinScore>@MaxScore
         And   IsActive=1
         order by MinScore Asc;
End;
go

create or alter procedure usp_CalculateGPA
                                @Score decimal(5,2),
                                @GPAPoint decimal(3,2),
                                @MinScore decimal(5,2),
                                @MinNextScore decimal(5,2),
                                @CalculatedGPA decimal(3,2) output
As
Begin
    Set nocount on;
    Set @CalculatedGPA=Round( @GPAPoint +(@Score-@MinScore)/(@MinNextScore-@MinScore),2,1);
End;



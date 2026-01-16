/*
 * DATABASE SETUP - SESSION 15 EXAM
 * Database: StudentManagement
 */

DROP DATABASE IF EXISTS StudentManagement;
CREATE DATABASE StudentManagement;
USE StudentManagement;

-- =============================================
-- 1. TABLE STRUCTURE
-- =============================================

-- Table: Students
CREATE TABLE Students (
    StudentID CHAR(5) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    TotalDebt DECIMAL(10,2) DEFAULT 0
);

-- Table: Subjects
CREATE TABLE Subjects (
    SubjectID CHAR(5) PRIMARY KEY,
    SubjectName VARCHAR(50) NOT NULL,
    Credits INT CHECK (Credits > 0)
);

-- Table: Grades
CREATE TABLE Grades (
    StudentID CHAR(5),
    SubjectID CHAR(5),
    Score DECIMAL(4,2) CHECK (Score BETWEEN 0 AND 10),
    PRIMARY KEY (StudentID, SubjectID),
    CONSTRAINT FK_Grades_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Grades_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID)
);

-- Table: GradeLog
CREATE TABLE GradeLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    StudentID CHAR(5),
    OldScore DECIMAL(4,2),
    NewScore DECIMAL(4,2),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. SEED DATA
-- =============================================

-- Insert Students
INSERT INTO Students (StudentID, FullName, TotalDebt) VALUES 
('SV01', 'Ho Khanh Linh', 5000000),
('SV03', 'Tran Thi Khanh Huyen', 0);

-- Insert Subjects
INSERT INTO Subjects (SubjectID, SubjectName, Credits) VALUES 
('SB01', 'Co so du lieu', 3),
('SB02', 'Lap trinh Java', 4),
('SB03', 'Lap trinh C', 3);

-- Cau 1: Nhà trường yêu cầu điểm số (Score) nhập vào hệ thống phải luôn hợp lệ (từ 0 đến 10).
-- Hãy viết một Trigger có tên tg_CheckScore chạy trước khi thêm (BEFORE INSERT) dữ liệu vào bảng Grades.

delimiter //
create trigger tg_CheckScore
before insert on Grades
for each row
begin
    if new.Score < 0 then
        set new.Score = 0;
    elseif new.Score > 10 then
        set new.Score = 10;
    end if;
end//
delimiter ;


-- Insert Grades
INSERT INTO Grades (StudentID, SubjectID, Score) VALUES 
('SV01', 'SB01', 8.5), -- Passed
('SV03', 'SB02', 3.0); -- Failed

-- Cau 2:Viết một đoạn script sử dụng Transaction để thêm một sinh viên mới. Yêu cầu đảm bảo tính trọn vẹn "All or Nothing" của dữ liệu:
-- Bắt đầu Transaction.
start transaction;
-- Thêm sinh viên mới vào bảng Students: StudentID = 'SV02', FullName = 'Ha Bich Ngoc'
insert into Students(StudentID, FullName) values ('SV02', 'Ha Bich Ngoc');
-- Cập nhật nợ học phí (TotalDebt) cho sinh viên này là 5,000,000
update Students set TotalDebt = TotalDebt + 5000000 where StudentID = 'SV02';
-- xac nhan commit
commit;


-- Cau 3:Để chống tiêu cực trong thi cử, mọi hành động sửa đổi điểm số cần được ghi lại.
-- Hãy viết Trigger tên tg_LogGradeUpdate chạy sau khi cập nhật (AFTER UPDATE) trên bảng Grades
delimiter //
create trigger tg_loggradeupdate
after update on grades
for each row
begin
    insert into gradelog (studentid, oldscore, newscore, changedate)
    values (old.studentid, old.score, new.score, now());
end//
delimiter ;

update grades set score = 9 where studentid = 'SV01' and subjectid = 'SB01';

-- cau 4: Viết một Stored Procedure đơn giản tên sp_PayTuition thực hiện việc đóng học phí cho sinh viên 'SV01' với số tiền 2,000,000.
delimiter //

create procedure sp_paytuition()
begin
    declare currentdebt decimal(10,2);

    start transaction;
    select totaldebt into currentdebt from students where studentid = 'sv01';
    update students set totaldebt = totaldebt - 2000000 where studentid = 'sv01';
    if currentdebt < 2000000 then
        rollback;
    else
        commit;
    end if;
end//
delimiter ;




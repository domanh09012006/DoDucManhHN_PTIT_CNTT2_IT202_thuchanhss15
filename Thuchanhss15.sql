drop database if exists mini_social_network;
create database mini_social_network;
use mini_social_network;

create table users (
   user_id int primary key auto_increment,
   username varchar(50) unique not null,
   password varchar(255) not null,
   email varchar(100) unique not null,
   created_at datetime default current_timestamp
);

create table posts (
    post_id int primary key auto_increment,
    user_id int,
    content text not null,
    created_at datetime default current_timestamp,
    foreign key (user_id) references users(user_id) on delete cascade
);

alter table posts add column like_count int default 0;

create table comments (
    comment_id int primary key auto_increment,
    post_id int,
    user_id int,
    content text not null,
    created_at datetime default current_timestamp,
    foreign key (post_id) references posts(post_id) on delete cascade,
    foreign key (user_id) references users(user_id) on delete cascade
);

create table likes (
    user_id int,
    post_id int,
    created_at datetime default current_timestamp,
    primary key (user_id, post_id),
    foreign key (user_id) references users(user_id) on delete cascade,
    foreign key (post_id) references posts(post_id) on delete cascade
);

create table friends (
    user_id int,
    friend_id int,
    status varchar(20) check (status in ('pending', 'accepted')) default 'pending',
    created_at datetime default current_timestamp,
    primary key (user_id, friend_id),
    foreign key (user_id) references users(user_id) on delete cascade,
    foreign key (friend_id) references users(user_id) on delete cascade
);

create table user_log (
    log_id int primary key auto_increment,
    user_id int,
    action varchar(50),
    log_time datetime default current_timestamp
);

create table post_log (
    log_id int primary key auto_increment,
    post_id int,
    action varchar(50),
    log_time datetime default current_timestamp
);

create table like_log (
    log_id int primary key auto_increment,
    user_id int,
    post_id int,
    action varchar(50),
    log_time datetime default current_timestamp
);

create table friend_log (
    log_id int primary key auto_increment,
    user_id int,
    friend_id int,
    action varchar(50),
    log_time datetime default current_timestamp
);

-- Bài 1: Đăng ký thành viên
delimiter //
create procedure sp_register_user(in p_username varchar(50), in p_password varchar(255), in p_email varchar(100))
begin
    declare v_user_count int;
    declare v_email_count int;

    select count(*) into v_user_count from users where username = p_username;
    if v_user_count > 0 then
            signal sqlstate '45000' set message_text = 'Username đã tồn tại';
    end if;

    select count(*) into v_email_count from users where email = p_email;
    if v_email_count > 0 then
            signal sqlstate '45000' set message_text = 'Email đã tồn tại';
    end if;

    insert into users (username, password, email) values (p_username, p_password, p_email);
end //
delimiter ;



delimiter //
create trigger trg_after_insert_user
    after insert on users
    for each row
begin
    insert into user_log (user_id, action) values (new.user_id, 'Registered');
end //
delimiter ;

-- Check
-- Success
call sp_register_user('user1', 'pass1', 'user1@email.com');
call sp_register_user('user2', 'pass2', 'user2@email.com');
call sp_register_user('user3', 'pass3', 'user3@email.com');
call sp_register_user('user4', 'pass4', 'user4@email.com');

select * from users;
select * from user_log;

-- Fail ( Email, Username -- Duplicate )
-- call sp_register_user('user1', 'pass', 'new@email.com');
-- call sp_register_user('newuser', 'pass', 'user1@email.com');

-- Bài 2: Đăng bài viết
delimiter //
create procedure sp_create_post(in p_user_id int, in p_content text)
begin
    if trim(p_content) = '' or p_content is null then
        signal sqlstate '45000' set message_text = 'Content không được rỗng';
    end if;
    insert into posts (user_id, content) values (p_user_id, p_content);
end //
delimiter ;

delimiter //
create trigger trg_after_insert_post
    after insert on posts
    for each row
begin
    insert into post_log (post_id, action) values (new.post_id, 'Created');
end //
delimiter ;

-- Check
-- Success
call sp_create_post(1, 'Bài viết 1 của user1');
call sp_create_post(1, 'Bài viết 2 của user1');
call sp_create_post(2, 'Bài viết 1 của user2');
call sp_create_post(3, 'Bài viết 1 của user3');
call sp_create_post(4, 'Bài viết 1 của user4');
call sp_create_post(2, 'Bài viết 2 của user2');

select * from posts;
select * from post_log;

-- Fail
-- call sp_create_post(1, '');

-- Bài 3: Thích bài viết
delimiter //
create trigger trg_after_insert_like
    after insert on likes
    for each row
begin
    update posts set like_count = like_count + 1 where post_id = new.post_id;
    insert into like_log (user_id, post_id, action) values (new.user_id, new.post_id, 'Liked');
end //
delimiter ;




delimiter //
create trigger trg_after_delete_like
    after delete on likes
    for each row
begin
    update posts set like_count = like_count - 1 where post_id = old.post_id;
    insert into like_log (user_id, post_id, action) values (old.user_id, old.post_id, 'Unliked');
end //
delimiter ;

-- Check
-- Success
insert into likes (user_id, post_id) values (2, 1); -- user2 like post1 của user1
insert into likes (user_id, post_id) values (3, 1);
insert into likes (user_id, post_id) values (4, 1);
insert into likes (user_id, post_id) values (1, 3); -- user1 like post1 của user2

select * from likes;
-- Check like cnt
select * from posts;
select * from like_log;

-- Unlike
delete from likes where user_id = 4 and post_id = 1;

-- Check like des
select * from posts;
select * from like_log;

-- Dup like (primary key ngăn)
-- insert into likes (user_id, post_id) values (2, 1);


delimiter //
create trigger trg_before_insert_like
    before insert on likes
    for each row
begin
    declare post_owner_id int;
    select user_id into post_owner_id from posts where post_id = new.post_id;
    if new.user_id = post_owner_id then
        signal sqlstate '45000' set message_text = 'Ko thể like post của chính mình!!';
end if;
end //
delimiter ;

-- Check
-- Success (Failed)
-- insert into likes (user_id, post_id) values (1, 1);

-- Bài 4: Gửi lời mời kết bạn
delimiter //
create procedure sp_send_friend_request(in p_sender_id int, in p_receiver_id int)
begin
    if p_sender_id = p_receiver_id then
        signal sqlstate '45000' set message_text = 'Ko thể gửi lời mời cho chính mình';
    end if;
    if exists (select 1 from friends where user_id = p_sender_id and friend_id = p_receiver_id) then
        signal sqlstate '45000' set message_text = 'Lời mời đã tồn tại';
    end if;

    insert into friends (user_id, friend_id) values (p_sender_id, p_receiver_id);
end //
delimiter ;


delimiter //
create trigger trg_after_insert_friend
    after insert on friends
    for each row
begin
    insert into friend_log (user_id, friend_id, action) values (new.user_id, new.friend_id, 'Sent request');
end //
delimiter ;

-- Check
-- Success (Send)
call sp_send_friend_request(1, 2);
call sp_send_friend_request(1, 3);
call sp_send_friend_request(2, 3);
call sp_send_friend_request(3, 4);

select * from friends;
select * from friend_log;

-- Fail (Seft, Dup)
-- call sp_send_friend_request(1, 1);
-- call sp_send_friend_request(1, 2);

-- Bài 5: Chấp nhận lời mời kết bạn
delimiter //
create trigger trg_after_update_friend
    after update on friends
    for each row
begin
    if new.status = 'accepted' and old.status = 'pending' then
        insert ignore into friends (user_id, friend_id, status) values (new.friend_id, new.user_id, 'accepted');
    insert into friend_log (user_id, friend_id, action) values (new.user_id, new.friend_id, 'accepted');
end if;
end //
delimiter ;

-- Check
-- Success ( Send -> Ac )
call sp_send_friend_request(4, 1);

update friends set status = 'accepted' where user_id = 4 and friend_id = 1;

-- Check - Disp
select * from friends;
select * from friend_log;

-- Bài 6: Quản lý mối quan hệ bạn bè (cập nhật/xóa với transaction)
-- Del in, out: 2 C: <->
delimiter //
create procedure sp_delete_friendship(in p_user_id int, in p_friend_id int)
begin
    declare exit handler for sqlexception rollback;

    start transaction;
    delete from friends where (user_id = p_user_id and friend_id = p_friend_id) or (user_id = p_friend_id and friend_id = p_user_id);
    insert into friend_log (user_id, friend_id, action) values (p_user_id, p_friend_id, 'deleted');
    commit;
end //
delimiter ;

-- Check
-- Success (Del)
call sp_delete_friendship(1, 2);

select * from friends;
select * from friend_log;

-- Gây lỗi (ví dụ xóa không tồn tại, nhưng procedure không lỗi, chỉ delete 0 rows)
-- Để test rollback, có thể thêm code gây lỗi trong procedure, ví dụ:
-- alter procedure thêm: if 1=0 then signal... else commit;

-- Bài 7: quản lý xóa bài viết
delimiter //
create procedure sp_delete_post(in p_post_id int, in p_user_id int)
begin
    declare post_owner int;
    declare exit handler for sqlexception rollback;

    start transaction;
    select user_id into post_owner from posts where post_id = p_post_id;
    if post_owner != p_user_id then
            signal sqlstate '45000' set message_text = 'Chỉ chủ bài viết mới được xóa';
    end if;

    -- Xóa likes và comments bằng cascade, chỉ delete post
    delete from posts where post_id = p_post_id;
    insert into post_log (post_id, action) values (p_post_id, 'deleted');
    commit;
end //
delimiter ;

-- Check
-- Data: post có like và comment
call sp_create_post(1, 'Bài viết để xóa');
set @post_id = last_insert_id();
insert into comments (post_id, user_id, content) values (@post_id, 2, 'comment1');
insert into likes (user_id, post_id) values (2, @post_id);
insert into likes (user_id, post_id) values (3, @post_id);

select * from posts where post_id = @post_id;
select * from comments where post_id = @post_id;
select * from likes where post_id = @post_id;

-- Del
call sp_delete_post(@post_id, 1);

-- 1. -- gone;  2-3. -- gone by cascade
select * from posts where post_id = @post_id;
select * from comments where post_id = @post_id;
select * from likes where post_id = @post_id;

select * from post_log;

-- Del ko phải Owner
-- Post 1, user 1
-- call sp_delete_post(1, 2);

-- Bài 8: Quản lý xóa tài khoản người dùng
delimiter //
create procedure sp_delete_user(in p_user_id int)
begin
    declare exit handler for sqlexception rollback;

    start transaction;
    -- Del = cascade: posts, comments, likes, friends
    delete from users where user_id = p_user_id;
    insert into user_log (user_id, action) values (p_user_id, 'deleted');
    commit;
end //
delimiter ;

-- Check
-- User full
call sp_register_user('user5', 'pass5', 'user5@email.com');
set @user5_id = last_insert_id();
call sp_create_post(@user5_id, 'Bài của user5');
set @post5_id = last_insert_id();
insert into comments (post_id, user_id, content) values (@post5_id, 1, 'comment5');
insert into likes (user_id, post_id) values (1, @post5_id);
call sp_send_friend_request(@user5_id, 1);

select * from users where user_id = @user5_id;
select * from posts where user_id = @user5_id;
select * from comments where post_id = @post5_id;
select * from likes where post_id = @post5_id;
select * from friends where user_id = @user5_id or friend_id = @user5_id;

-- Del
call sp_delete_user(@user5_id);

-- Gone
select * from users where user_id = @user5_id;
select * from posts where user_id = @user5_id;
select * from comments where post_id = @post5_id;
select * from likes where post_id = @post5_id;
select * from friends where user_id = @user5_id or friend_id = @user5_id;
select * from user_log;

-- B1: Duplicate: select 1 from users where username = p_username :  exists ()
-- B2: if p_content = '' or p_content is null then
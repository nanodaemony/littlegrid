-- 移除 username 列的迁移脚本（用于已执行过 V1 的数据库）
ALTER TABLE `grid_user` DROP INDEX `uk_username`;
ALTER TABLE `grid_user` DROP COLUMN `username`;

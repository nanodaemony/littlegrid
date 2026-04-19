-- 数据管理菜单初始化脚本
-- 新增【数据管理】一级菜单及子菜单

-- 1. 添加一级菜单【数据管理】
INSERT INTO `sys_menu` (`menu_id`, `pid`, `sub_count`, `type`, `title`, `name`, `component`, `menu_sort`, `icon`, `path`, `i_frame`, `cache`, `hidden`, `permission`, `create_by`, `update_by`, `create_time`, `update_time`)
VALUES (210, NULL, 1, 0, '数据管理', 'DataManagement', NULL, 99, 'date', 'data-management', b'0', b'0', b'0', NULL, 'admin', NULL, NOW(), NULL);

-- 2. 添加子菜单 - 数据库浏览器
INSERT INTO `sys_menu` (`menu_id`, `pid`, `sub_count`, `type`, `title`, `name`, `component`, `menu_sort`, `icon`, `path`, `i_frame`, `cache`, `hidden`, `permission`, `create_by`, `update_by`, `create_time`, `update_time`)
VALUES (211, 210, 4, 1, '数据库浏览器', 'DatabaseBrowser2', 'dataManagement/databaseBrowser/index', 1, 'date', 'database-browser', b'0', b'0', b'0', 'databaseBrowser:list', 'admin', NULL, NOW(), NULL);

-- 3. 添加子菜单权限 - 查看
INSERT INTO `sys_menu` (`menu_id`, `pid`, `sub_count`, `type`, `title`, `name`, `component`, `menu_sort`, `icon`, `path`, `i_frame`, `cache`, `hidden`, `permission`, `create_by`, `update_by`, `create_time`, `update_time`)
VALUES (212, 211, 0, 2, '查看', NULL, NULL, 1, NULL, NULL, b'0', b'0', b'0', 'databaseBrowser:list', 'admin', NULL, NOW(), NULL);

-- 4. 添加子菜单权限 - 新增
INSERT INTO `sys_menu` (`menu_id`, `pid`, `sub_count`, `type`, `title`, `name`, `component`, `menu_sort`, `icon`, `path`, `i_frame`, `cache`, `hidden`, `permission`, `create_by`, `update_by`, `create_time`, `update_time`)
VALUES (213, 211, 0, 2, '新增', NULL, NULL, 2, NULL, NULL, b'0', b'0', b'0', 'databaseBrowser:add', 'admin', NULL, NOW(), NULL);

-- 5. 添加子菜单权限 - 编辑
INSERT INTO `sys_menu` (`menu_id`, `pid`, `sub_count`, `type`, `title`, `name`, `component`, `menu_sort`, `icon`, `path`, `i_frame`, `cache`, `hidden`, `permission`, `create_by`, `update_by`, `create_time`, `update_time`)
VALUES (214, 211, 0, 2, '编辑', NULL, NULL, 3, NULL, NULL, b'0', b'0', b'0', 'databaseBrowser:edit', 'admin', NULL, NOW(), NULL);

-- 6. 添加子菜单权限 - 删除
INSERT INTO `sys_menu` (`menu_id`, `pid`, `sub_count`, `type`, `title`, `name`, `component`, `menu_sort`, `icon`, `path`, `i_frame`, `cache`, `hidden`, `permission`, `create_by`, `update_by`, `create_time`, `update_time`)
VALUES (215, 211, 0, 2, '删除', NULL, NULL, 4, NULL, NULL, b'0', b'0', b'0', 'databaseBrowser:del', 'admin', NULL, NOW(), NULL);

-- 7. 更新旧菜单的component路径，指向新位置
UPDATE `sys_menu` SET `component` = 'dataManagement/databaseBrowser/index' WHERE `menu_id` = 200;

package com.naon.grid.modules.app.treehole.repository;

import com.naon.grid.modules.app.treehole.domain.TreeholeViewHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.sql.Date;
import java.util.List;

@Repository
public interface TreeholeViewHistoryRepository extends JpaRepository<TreeholeViewHistory, Long>, JpaSpecificationExecutor<TreeholeViewHistory> {

    /**
     * 查询用户某天已浏览的帖子ID列表
     */
    @Query("SELECT h.postId FROM TreeholeViewHistory h WHERE h.userId = :userId AND h.viewDate = :viewDate")
    List<Long> findViewedPostIds(@Param("userId") Long userId, @Param("viewDate") Date viewDate);

    /**
     * 删除某帖子的浏览历史
     */
    @Modifying
    @Query("DELETE FROM TreeholeViewHistory h WHERE h.postId = :postId")
    void deleteByPostId(@Param("postId") Long postId);
}

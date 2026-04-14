package com.naon.grid.modules.app.treehole.repository;

import com.naon.grid.modules.app.treehole.domain.TreeholeReplyLike;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TreeholeReplyLikeRepository extends JpaRepository<TreeholeReplyLike, Long>, JpaSpecificationExecutor<TreeholeReplyLike> {

    /**
     * 检查是否已点赞
     */
    boolean existsByReplyIdAndUserId(Long replyId, Long userId);

    /**
     * 查询点赞记录
     */
    Optional<TreeholeReplyLike> findByReplyIdAndUserId(Long replyId, Long userId);

    /**
     * 查询用户对某批回复的点赞状态
     */
    @Query("SELECT l.replyId FROM TreeholeReplyLike l WHERE l.replyId IN :replyIds AND l.userId = :userId")
    List<Long> findLikedReplyIds(@Param("replyIds") List<Long> replyIds, @Param("userId") Long userId);

    /**
     * 删除某回复的所有点赞
     */
    @Modifying
    @Query("DELETE FROM TreeholeReplyLike l WHERE l.replyId = :replyId")
    void deleteByReplyId(@Param("replyId") Long replyId);

    /**
     * 删除某帖子所有回复的点赞(通过回复ID列表)
     */
    @Modifying
    @Query("DELETE FROM TreeholeReplyLike l WHERE l.replyId IN :replyIds")
    void deleteByReplyIds(@Param("replyIds") List<Long> replyIds);
}

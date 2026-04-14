package com.naon.grid.modules.app.treehole.repository;

import com.naon.grid.modules.app.treehole.domain.TreeholeReply;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TreeholeReplyRepository extends JpaRepository<TreeholeReply, Long>, JpaSpecificationExecutor<TreeholeReply> {

    /**
     * 查询帖子的所有一级回复
     */
    List<TreeholeReply> findByPostIdAndParentIdIsNullOrderByCreatedAtDesc(Long postId);

    /**
     * 查询某个回复的子回复
     */
    List<TreeholeReply> findByParentIdOrderByCreatedAtAsc(Long parentId);

    /**
     * 删除帖子的所有回复
     */
    @Modifying
    @Query("DELETE FROM TreeholeReply r WHERE r.postId = :postId")
    void deleteByPostId(@Param("postId") Long postId);

    /**
     * 删除回复的所有子回复
     */
    @Modifying
    @Query("DELETE FROM TreeholeReply r WHERE r.parentId = :parentId")
    void deleteByParentId(@Param("parentId") Long parentId);

    /**
     * 增加点赞数
     */
    @Modifying
    @Query("UPDATE TreeholeReply r SET r.likeCount = r.likeCount + 1 WHERE r.id = :replyId")
    void incrementLikeCount(@Param("replyId") Long replyId);

    /**
     * 减少点赞数
     */
    @Modifying
    @Query("UPDATE TreeholeReply r SET r.likeCount = r.likeCount - 1 WHERE r.id = :replyId AND r.likeCount > 0")
    void decrementLikeCount(@Param("replyId") Long replyId);
}

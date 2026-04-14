package com.naon.grid.modules.app.treehole.repository;

import com.naon.grid.modules.app.treehole.domain.TreeholePost;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TreeholePostRepository extends JpaRepository<TreeholePost, Long>, JpaSpecificationExecutor<TreeholePost> {

    /**
     * 查询用户发布的帖子
     */
    Page<TreeholePost> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    /**
     * 随机获取帖子(排除自己的和已浏览的)
     */
    @Query(value = "SELECT p FROM TreeholePost p WHERE p.userId != :userId " +
           "AND p.id NOT IN :viewedPostIds " +
           "AND (:tag IS NULL OR p.tag = :tag) " +
           "ORDER BY FUNCTION('RAND')")
    List<TreeholePost> findRandomPosts(
            @Param("userId") Long userId,
            @Param("viewedPostIds") List<Long> viewedPostIds,
            @Param("tag") String tag,
            Pageable pageable);

    /**
     * 随机获取帖子(只排除自己的,没有浏览历史)
     */
    @Query(value = "SELECT p FROM TreeholePost p WHERE p.userId != :userId " +
           "AND (:tag IS NULL OR p.tag = :tag) " +
           "ORDER BY FUNCTION('RAND')")
    List<TreeholePost> findRandomPostsWithoutViewHistory(
            @Param("userId") Long userId,
            @Param("tag") String tag,
            Pageable pageable);

    /**
     * 统计帖子的回复数
     */
    @Query("SELECT COUNT(r) FROM TreeholeReply r WHERE r.postId = :postId")
    Long countRepliesByPostId(@Param("postId") Long postId);
}

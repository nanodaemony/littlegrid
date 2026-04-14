package com.naon.grid.modules.app.treehole.service;

import com.naon.grid.modules.app.treehole.service.dto.*;
import com.naon.grid.utils.PageResult;
import org.springframework.data.domain.Pageable;

public interface TreeholeService {

    PostDTO createPost(Long userId, CreatePostDTO dto);

    PostDTO getRandomPost(Long userId, String tag);

    PageResult<PostDTO> getMyPosts(Long userId, Pageable pageable);

    PostDetailDTO getPostDetail(Long postId, Long userId);

    void deletePost(Long postId, Long userId);

    ReplyDTO createReply(Long postId, Long userId, CreateReplyDTO dto);

    LikeResultDTO likeReply(Long replyId, Long userId);

    LikeResultDTO unlikeReply(Long replyId, Long userId);

    @lombok.Data
    @lombok.Builder
    @lombok.AllArgsConstructor
    @lombok.NoArgsConstructor
    class LikeResultDTO {
        private Long id;
        private Integer likeCount;
    }
}

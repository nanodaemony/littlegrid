package com.naon.grid.modules.app.treehole.service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReplyDTO {

    private Long id;
    private Long postId;
    private String content;
    private Long parentId;
    private Integer likeCount;
    private Boolean isLiked;
    private Long createdAt;
    private List<ReplyDTO> children;
}

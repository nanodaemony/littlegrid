package com.naon.grid.modules.app.treehole.service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PostDTO {

    private Long id;
    private String content;
    private String tag;
    private Long createdAt;
    private Long replyCount;
}

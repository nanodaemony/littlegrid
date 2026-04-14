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
public class PostDetailDTO {

    private PostDTO post;
    private List<ReplyDTO> replies;
}

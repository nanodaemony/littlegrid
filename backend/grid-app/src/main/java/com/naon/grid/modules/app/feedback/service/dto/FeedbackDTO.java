package com.naon.grid.modules.app.feedback.service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeedbackDTO {
    private Long id;
    private Long userId;
    private String type;
    private String description;
    private String status;
    private Long createdAt;
}

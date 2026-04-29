package com.naon.grid.modules.app.feedback.service.impl;

import com.alibaba.fastjson2.JSON;
import com.naon.grid.modules.app.feedback.domain.Feedback;
import com.naon.grid.modules.app.feedback.enums.FeedbackStatus;
import com.naon.grid.modules.app.feedback.enums.FeedbackType;
import com.naon.grid.modules.app.feedback.repository.FeedbackRepository;
import com.naon.grid.modules.app.feedback.service.FeedbackService;
import com.naon.grid.modules.app.feedback.service.dto.FeedbackDTO;
import com.naon.grid.modules.app.feedback.service.dto.SubmitFeedbackDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class FeedbackServiceImpl implements FeedbackService {

    private final FeedbackRepository feedbackRepository;

    @Override
    @Transactional
    public FeedbackDTO submitFeedback(Long userId, SubmitFeedbackDTO dto) {
        Feedback feedback = new Feedback();
        feedback.setUserId(userId);
        feedback.setType(FeedbackType.valueOf(dto.getType()));
        feedback.setDescription(dto.getDescription());
        feedback.setStatus(FeedbackStatus.PENDING);

        if (dto.getScreenshots() != null && !dto.getScreenshots().isEmpty()) {
            feedback.setScreenshots(JSON.toJSONString(dto.getScreenshots()));
        }

        feedback = feedbackRepository.save(feedback);
        return toFeedbackDTO(feedback);
    }

    private FeedbackDTO toFeedbackDTO(Feedback feedback) {
        return FeedbackDTO.builder()
                .id(feedback.getId())
                .userId(feedback.getUserId())
                .type(feedback.getType().name())
                .description(feedback.getDescription())
                .status(feedback.getStatus().name())
                .createdAt(feedback.getCreatedAt().getTime())
                .build();
    }
}

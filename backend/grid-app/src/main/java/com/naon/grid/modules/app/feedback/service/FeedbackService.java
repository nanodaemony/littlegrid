package com.naon.grid.modules.app.feedback.service;

import com.naon.grid.modules.app.feedback.service.dto.FeedbackDTO;
import com.naon.grid.modules.app.feedback.service.dto.SubmitFeedbackDTO;

public interface FeedbackService {

    FeedbackDTO submitFeedback(Long userId, SubmitFeedbackDTO dto);
}

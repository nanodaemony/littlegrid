package com.naon.grid.modules.app.feedback.enums;

public enum FeedbackStatus {
    PENDING("待处理"),
    READ("已读");

    private final String description;

    FeedbackStatus(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}

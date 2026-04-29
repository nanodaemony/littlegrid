package com.naon.grid.modules.app.feedback.enums;

public enum FeedbackType {
    SUGGESTION("功能建议"),
    ISSUE("问题反馈");

    private final String description;

    FeedbackType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}

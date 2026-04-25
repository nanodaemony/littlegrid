package com.naon.grid.config.webConfig;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.MDC;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import javax.servlet.ServletException;
import java.io.IOException;

import static org.junit.jupiter.api.Assertions.*;

class TraceFilterTest {

    private TraceFilter traceFilter;
    private MockFilterChain filterChain;
    private MockHttpServletRequest request;
    private MockHttpServletResponse response;

    @BeforeEach
    void setUp() {
        traceFilter = new TraceFilter();
        filterChain = new MockFilterChain();
        request = new MockHttpServletRequest();
        response = new MockHttpServletResponse();
        MDC.clear();
    }

    @AfterEach
    void tearDown() {
        MDC.clear();
    }

    @Test
    void shouldUseTraceIdFromHeader() throws ServletException, IOException {
        request.addHeader("X-Trace-Id", "test-trace-123");

        traceFilter.doFilter(request, response, filterChain);

        assertEquals("test-trace-123", response.getHeader("X-Trace-Id"));
    }

    @Test
    void shouldGenerateTraceIdWhenHeaderMissing() throws ServletException, IOException {
        traceFilter.doFilter(request, response, filterChain);

        String traceId = response.getHeader("X-Trace-Id");
        assertNotNull(traceId);
        assertFalse(traceId.isEmpty());
    }

    @Test
    void shouldGenerateTraceIdWhenHeaderEmpty() throws ServletException, IOException {
        request.addHeader("X-Trace-Id", "");

        traceFilter.doFilter(request, response, filterChain);

        String traceId = response.getHeader("X-Trace-Id");
        assertNotNull(traceId);
        assertFalse(traceId.isEmpty());
    }

    @Test
    void shouldClearMdcAfterFilter() throws ServletException, IOException {
        request.addHeader("X-Trace-Id", "test-trace-456");
        traceFilter.doFilter(request, response, filterChain);

        assertNull(MDC.get("traceId"));
    }

    @Test
    void shouldClearMdcEvenOnException() throws ServletException, IOException {
        request.addHeader("X-Trace-Id", "test-trace-789");
        MockFilterChain failingChain = new MockFilterChain() {
            @Override
            public void doFilter(javax.servlet.ServletRequest request, javax.servlet.ServletResponse response) {
                throw new RuntimeException("Simulated error");
            }
        };

        assertThrows(RuntimeException.class, () -> {
            traceFilter.doFilter(request, response, failingChain);
        });

        assertNull(MDC.get("traceId"));
    }
}

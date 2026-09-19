package com.pharmacy.common.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.Optional;

/**
 * Interceptor that runs before every API request to validate the Bearer token.
 * Populates the TenantContext with the authenticated user.
 */
@Component
public class TenantInterceptor implements HandlerInterceptor {

    private final AuthDao authDao;

    public TenantInterceptor(AuthDao authDao) {
        this.authDao = authDao;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        
        // CORS preflight requests should pass
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\": \"Unauthorized: Missing or invalid token\"}");
            return false;
        }

        String token = authHeader.substring(7);
        Optional<User> userOpt = authDao.getUserByToken(token);

        if (userOpt.isEmpty()) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\": \"Unauthorized: Invalid or expired token\"}");
            return false;
        }

        // Token is valid, set context
        TenantContext.setCurrentUser(userOpt.get());
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
        // Prevent memory leaks
        TenantContext.clear();
    }
}

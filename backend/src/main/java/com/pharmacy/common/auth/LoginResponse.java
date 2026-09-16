package com.pharmacy.common.auth;

/**
 * DTO for login responses. Returns user info and a session token.
 * Password is never included in responses.
 */
public class LoginResponse {

    private Long id;
    private String username;
    private String fullName;
    private String role;
    private String token;

    public LoginResponse() {
    }

    public LoginResponse(Long id, String username, String fullName, String role, String token) {
        this.id = id;
        this.username = username;
        this.fullName = fullName;
        this.role = role;
        this.token = token;
    }

    // Getters and setters

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }
}

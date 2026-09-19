package com.pharmacy.common.auth;

/**
 * ThreadLocal context to hold the current authenticated user and their tenant (pharmacy) ID.
 * This is populated by the TenantInterceptor on every secured API request.
 */
public class TenantContext {

    private static final ThreadLocal<User> currentUser = new ThreadLocal<>();

    public static void setCurrentUser(User user) {
        currentUser.set(user);
    }

    public static User getCurrentUser() {
        return currentUser.get();
    }

    public static Long getCurrentPharmacyId() {
        User user = currentUser.get();
        return user != null ? user.getPharmacyId() : null;
    }

    public static void clear() {
        currentUser.remove();
    }
}

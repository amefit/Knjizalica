namespace Knjizalica.Shared.Constants;

public static class RoleNames
{
    public const string Admin = "Admin";
    public const string User = "User";
}

public static class RabbitMqConstants
{
    public const string ExchangeName = "knjizalica.events";
    public const string EmailQueue = "knjizalica.email";
    public const string NotificationQueue = "knjizalica.notifications";
}

public static class LoanStatusNames
{
    public const string Pending = "Pending";
    public const string Confirmed = "Confirmed";
    public const string Completed = "Completed";
    public const string Cancelled = "Cancelled";
    public const string Overdue = "Overdue";
}

public static class ReservationStatusNames
{
    public const string Pending = "Pending";
    public const string Confirmed = "Confirmed";
    public const string Completed = "Completed";
    public const string Cancelled = "Cancelled";
}

public static class MembershipStatusNames
{
    public const string Active = "Active";
    public const string Blocked = "Blocked";
    public const string Expired = "Expired";
}

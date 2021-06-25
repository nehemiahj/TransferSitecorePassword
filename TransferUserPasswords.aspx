<%@ Page Language="C#" AutoEventWireup="true" Inherits="Sitecore.sitecore.admin.CacheAdmin" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Drawing" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.Sites" %>
<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Collections" %>
<%@ Import Namespace="Sitecore.Diagnostics" %>
<%@ Import Namespace="Sitecore.Security.Domains" %>
<%@ Import Namespace="Sitecore.Security.Accounts" %>
<%@ Import Namespace="System.Data.SqlClient" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<script runat="server">
    private static Dictionary<string, string> users1;
    private static Dictionary<string, string> users2;

    protected override void OnInit(EventArgs arguments)
    {
        base.CheckSecurity(true);
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            lblError.Text = null;
            ClearListBoxes();
        }
    }

    protected void btnAdd_Click(object sender, EventArgs e)
    {
        System.Web.UI.WebControls.ListItem listItem = lbUsersIntersect.SelectedItem;
        if (listItem != null)
        {
            ClearListBoxSelection();
            lbTransferPasswords.Items.Add(listItem);
            lbUsersIntersect.Items.Remove(listItem);
        }
    }

    protected void btnRemove_Click(object sender, EventArgs e)
    {
        System.Web.UI.WebControls.ListItem listItem = lbTransferPasswords.SelectedItem;
        if (listItem != null)
        {
            ClearListBoxSelection();
            lbUsersIntersect.Items.Add(listItem);
            lbTransferPasswords.Items.Remove(listItem);
        }
    }

    protected void btnRefresh_Click(object sender, EventArgs e)
    {
        ClearListBoxes();
        if (!String.IsNullOrEmpty(tbSQL1.Text) && !String.IsNullOrEmpty(tbSQL2.Text) && tbSQL1.Text != tbSQL2.Text)
        {
            users1 = SelectUsers(tbSQL1.Text);
            users2 = SelectUsers(tbSQL2.Text);
            if (users1 != null && users2 != null)
            {
                lbUsersIntersect.DataSource = users1.Where(x => users2.ContainsValue(x.Value)).ToDictionary(x => x.Key, x => x.Value);
                lbUsersIntersect.DataBind();
            }
            else
            {
                SetErrorMessage(Color.Red, "Users that exist in both core databases are missing!");
            }
        }
        else
        {
            SetErrorMessage(Color.Red, "Connection strings cannot be empty or equal each other!");
        }
    }

    protected void btnTransfer_Click(object sender, EventArgs e)
    {
        if (lbTransferPasswords.Items != null && lbTransferPasswords.Items.Count > 0)
        {
            int count = UpdatePasswords(tbSQL2.Text, SelectPasswords(tbSQL1.Text, lbTransferPasswords.Items));
            SetErrorMessage(Color.Green, String.Format("{0} user passwords were transferred successfully!", count));
            btnRefresh_Click(sender, e);
        }
        else
        {
            SetErrorMessage(Color.Red, "The list of users whose passwords will be transferred cannot be empty!");
        }
    }

    protected void btnTransferAll_Click(object sender, EventArgs e)
    {
        if (lbUsersIntersect.Items != null && lbUsersIntersect.Items.Count > 0)
        {
            int count = UpdatePasswords(tbSQL2.Text, SelectPasswords(tbSQL1.Text, lbUsersIntersect.Items));
            SetErrorMessage(Color.Green, String.Format("{0} user passwords were transferred successfully!", count));
            btnRefresh_Click(sender, e);
        }
        else
        {
            SetErrorMessage(Color.Red, "The list of users whose passwords will be transferred cannot be empty!");
        }
    }
    private void ClearListBoxes()
    {
        lbUsersIntersect.Items.Clear();
        lbTransferPasswords.Items.Clear();
    }

    private void ClearListBoxSelection()
    {
        lbUsersIntersect.ClearSelection();
        lbTransferPasswords.ClearSelection();
    }

    private void SetErrorMessage(Color color, string message)
    {
        lblError.ForeColor = color;
        lblError.Text = lblError.Text + " ==== " + message;
    }

    private Dictionary<string, string> SelectUsers(string connectionString)
    {
        Dictionary<string, string> users = new Dictionary<string, string>();
        SqlConnection connection = new SqlConnection();
        connection.ConnectionString = connectionString;
        SqlCommand command = new SqlCommand();
        command.Connection = connection;
        command.CommandText = "SELECT [UserId], [UserName] FROM [dbo].[aspnet_Users];";
        try
        {
            connection.Open();
            SqlDataReader reader = command.ExecuteReader();
            while (reader.Read())
            {
                users.Add(reader["UserId"].ToString(), reader["UserName"].ToString());
            }
            reader.Close();
        }
        catch (Exception exception)
        {
            SetErrorMessage(Color.Red, exception.Message);
        }
        finally
        {
            connection.Close();
        }
        return users;
    }

    private Dictionary<string, KeyValuePair<string, string>> SelectPasswords(string connectionString, System.Web.UI.WebControls.ListItemCollection users)
    {
        Dictionary<string, KeyValuePair<string, string>> passwords = new Dictionary<string, KeyValuePair<string, string>>();
        SqlConnection connection = new SqlConnection();
        connection.ConnectionString = connectionString;
        SqlCommand command = new SqlCommand();
        command.Connection = connection;
        command.CommandText = String.Format("SELECT [UserId], [Password], [PasswordSalt] FROM [dbo].[aspnet_Membership] WHERE [UserId] = '{0}'", users[0].Value);
        for (int i = 1; i < users.Count; i++)
        {
            command.CommandText += String.Format(" OR [UserId] = '{0}'", users[i].Value);
        }
        try
        {
            connection.Open();
            SqlDataReader reader = command.ExecuteReader();
            while (reader.Read())
            {
                passwords.Add(users2.FirstOrDefault(u2 => u2.Value == users1.FirstOrDefault(u1 => u1.Key == reader["UserId"].ToString()).Value).Key, 
                    new KeyValuePair<string, string>(reader["Password"].ToString(), reader["PasswordSalt"].ToString()));
            }
            reader.Close();
        }
        catch (Exception exception)
        {
            SetErrorMessage(Color.Red, exception.Message);
        }
        finally
        {
            connection.Close();
        }
        return passwords;
    }

    private int UpdatePasswords(string connectionString, Dictionary<string, KeyValuePair<string, string>> passwords)
    {
        SqlConnection connection = new SqlConnection();
        connection.ConnectionString = connectionString;
        SqlCommand command = new SqlCommand();
        command.Connection = connection;
        int count = 0;
        try
        {
            connection.Open();
            foreach (KeyValuePair<string, KeyValuePair<string, string>> password in passwords)
            {
                command.CommandText = String.Format("UPDATE [dbo].[aspnet_Membership] SET [Password] = '{0}', [PasswordSalt] = '{1}' WHERE UserId = '{2}';",
                    password.Value.Key, password.Value.Value, password.Key);

                count += command.ExecuteNonQuery();
            }
        }
        catch (Exception exception)
        {
            SetErrorMessage(Color.Red, exception.Message);
        }
        finally
        {
            connection.Close();
        }
        return count;
    }

</script>
<style>
    #btnAdd, #btnRemove {
        vertical-align: central;
    }
    #divMain {
        width: 700px;
    }
    #divListBoxes {
        margin-top: 20px;
    }
    #tbSQL1, #tbSQL2 {
        width: 100%;
    }
    #lbUsersIntersect, #lbTransferPasswords {
        width: 300px;
        height: 600px;
    }
</style>
<html xmlns="http://www.w3.org/1999/xhtml">
    <head id="Head1" runat="server">
      <title>Transfer User Passwords</title>
    </head>
    <body>
        <form id="Form1" runat="server">
            <div id="divMain">
                <p>
                    <b><asp:Label ID="lblError" runat="server" EnableViewState="false"></asp:Label></b>
                </p>
                <p>
                    <asp:Label ID="lblSQL1" runat="server" Text="Connection string for the source core database:"></asp:Label>
                    <br />
                    <asp:TextBox ID="tbSQL1" ToolTip="Connection string for the source core database" runat="server" Text="user id=user;password=password;Data Source=(server);Database=Sitecore_Core" /> 
                </p>
                <p>
                    <asp:Label ID="lblSQL2" runat="server" Text="Connection string for the target core database:"></asp:Label>
                    <br />
                    <asp:TextBox ID="tbSQL2" ToolTip="Connection string for the target core database" runat="server" Text="user id=user;password=password;Data Source=(server);Database=Sitecore_Core" /> 
                </p>
                <p>
                    <asp:Label ID="lblActions" runat="server" Text="Actions:"></asp:Label>
                    <asp:Button ID="btnRefresh" runat="server" Text="Refresh" OnClick="btnRefresh_Click" />
                    <asp:Button ID="btnTransfer" runat="server" Text="Transfer" OnClick="btnTransfer_Click" />
                    <asp:Button ID="btnTransferAll" runat="server" Text="Transfer All" OnClick="btnTransferAll_Click" />
                </p>
            </div>
            <div id="divListBoxes">
                <table>
                    <tr>
                        <td>
                            <asp:Label ID="lblAllUsers" runat="server" Text="Users that exist in both core databases:"></asp:Label><br/>
                            <asp:ListBox ID="lbUsersIntersect" runat="server" DataTextField="Value" DataValueField="Key"></asp:ListBox>
                        </td>
                        <td>
                            <asp:Button ID="btnRemove" runat="server" Text="<<<" OnClick="btnRemove_Click" />
                            <asp:Button ID="btnAdd" runat="server" Text=">>>" OnClick="btnAdd_Click" />
                        </td>
                        <td>
                            <asp:Label ID="lblTransferredUsers1" runat="server" Text="Users whose passwords will be transferred"></asp:Label><br/>
                            <asp:Label ID="lblTransferredUsers2" runat="server" Text="to the target core database:"></asp:Label><br/>
                            <asp:ListBox ID="lbTransferPasswords" runat="server" DataTextField="Value" DataValueField="Key"></asp:ListBox>
                        </td>
                    </tr>
                </table>
            </div>
        </form>
    </body>
</html>
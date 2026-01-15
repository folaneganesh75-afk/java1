import javax.servlet.ServletException;
import javax.servlet.http.*;
import javax.servlet.annotation.WebServlet;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/*")
public class MainServlet extends HttpServlet {

    // ================= DATABASE CONFIG =================
    private static final String DB_URL =
            "jdbc:mysql://localhost:3306/testdb";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "root";

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    // ================= HTTP HANDLER =================
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        String path = req.getPathInfo();
        if (path == null) path = "/";

        HttpSession session = req.getSession();
        PrintWriter out = res.getWriter();
        res.setContentType("text/html");

        if (path.equals("/") || path.equals("/login")) {
            showLogin(out);
        }
        else if (path.equals("/logout")) {
            session.invalidate();
            res.sendRedirect("login");
        }
        else if (path.equals("/users")) {
            if (!isLoggedIn(session)) {
                res.sendRedirect("login");
                return;
            }
            showUsers(out);
        }
        else if (path.equals("/delete")) {
            deleteUser(req);
            res.sendRedirect("users");
        }
        else {
            out.println("<h1>404 Not Found</h1>");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        String path = req.getPathInfo();
        if (path == null) path = "";

        if (path.equals("/login")) {
            login(req, res);
        }
        else if (path.equals("/add")) {
            addUser(req);
            res.sendRedirect("users");
        }
    }

    // ================= BUSINESS LOGIC =================
    private boolean isLoggedIn(HttpSession s) {
        return s.getAttribute("user") != null;
    }

    private Connection db() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }

    private void login(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        String u = req.getParameter("user");
        String p = req.getParameter("pass");

        try (Connection c = db()) {
            PreparedStatement ps =
                c.prepareStatement(
                    "SELECT * FROM users WHERE username=? AND password=?");
            ps.setString(1, u);
            ps.setString(2, p);

            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                req.getSession().setAttribute("user", u);
                res.sendRedirect("users");
                return;
            }
        } catch (Exception ignored) {}

        res.getWriter().println("<h3>Login failed</h3>");
        showLogin(res.getWriter());
    }

    private List<String> allUsers() {
        List<String> list = new ArrayList<>();
        try (Connection c = db()) {
            ResultSet rs =
                c.createStatement()
                 .executeQuery("SELECT username FROM users");
            while (rs.next()) list.add(rs.getString(1));
        } catch (Exception ignored) {}
        return list;
    }

    private void addUser(HttpServletRequest req) {
        try (Connection c = db()) {
            PreparedStatement ps =
                c.prepareStatement(
                    "INSERT INTO users(username,password) VALUES(?,?)");
            ps.setString(1, req.getParameter("user"));
            ps.setString(2, req.getParameter("pass"));
            ps.executeUpdate();
        } catch (Exception ignored) {}
    }

    private void deleteUser(HttpServletRequest req) {
        try (Connection c = db()) {
            PreparedStatement ps =
                c.prepareStatement(
                    "DELETE FROM users WHERE username=?");
            ps.setString(1, req.getParameter("user"));
            ps.executeUpdate();
        } catch (Exception ignored) {}
    }

    // ================= HTML VIEWS =================
    private void showLogin(PrintWriter out) {
        out.println("""
        <html><body>
        <h2>Login</h2>
        <form method='post' action='login'>
            <input name='user' placeholder='username'><br>
            <input name='pass' type='password' placeholder='password'><br>
            <button>Login</button>
        </form>
        </body></html>
        """);
    }

    private void showUsers(PrintWriter out) {
        out.println("<html><body><h2>Users</h2>");

        for (String u : allUsers()) {
            out.println(u +
              " <a href='delete?user=" + u + "'>delete</a><br>");
        }

        out.println("""
        <h3>Add User</h3>
        <form method='post' action='add'>
            <input name='user'>
            <input name='pass'>
            <button>Add</button>
        </form>

        <br><a href='logout'>Logout</a>
        </body></html>
        """);
    }
}


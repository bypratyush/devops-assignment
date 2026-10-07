import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;

/**
 * Hello World - Java in a container.
 * Uses the JDK's built-in HTTP server (com.sun.net.httpserver), so there are no
 * dependencies and no framework: the whole app is this one class.
 */
public class HelloWorld {

    public static void main(String[] args) throws IOException {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/healthz", ex -> send(ex, 200, "application/json", "{\"status\":\"ok\"}"));
        server.createContext("/", HelloWorld::index);
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        server.start();
        System.out.println("java-app listening on :" + port);

        // docker stop sends SIGTERM; the JVM runs shutdown hooks on SIGTERM.
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("SIGTERM received, stopping server");
            server.stop(1);
        }));
    }

    private static void index(HttpExchange ex) throws IOException {
        if (!ex.getRequestURI().getPath().equals("/")) {
            send(ex, 404, "text/plain", "not found\n");
            return;
        }
        String html = """
            <!doctype html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
              <title>Hello World - Java</title>
              <style>
                body { font-family: system-ui, sans-serif; background: #fbf5ef; color: #2b2118; margin: 0; }
                main { max-width: 640px; margin: 60px auto; padding: 32px 40px; background: #fff;
                       border-top: 6px solid #e76f00; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,.08); }
                h1 { margin: 0 0 8px; color: #b85c00; }
                td { padding: 4px 16px 4px 0; } td:first-child { color: #667; }
                footer { margin-top: 24px; font-size: 14px; color: #556; }
              </style>
            </head>
            <body>
              <main>
                <h1>Hello World from Java</h1>
                <p>The JDK's built-in HTTP server, running inside a Docker container.</p>
                <table>
                  <tr><td>Runtime</td><td>Java %s (%s)</td></tr>
                  <tr><td>Container hostname</td><td>%s</td></tr>
                  <tr><td>Platform</td><td>%s/%s</td></tr>
                </table>
                <footer>Built by Pratyush Mohanty (Roll No. 24BCS10238)</footer>
              </main>
            </body>
            </html>
            """.formatted(
                System.getProperty("java.version"),
                System.getProperty("java.vm.vendor"),
                InetAddress.getLocalHost().getHostName(),
                System.getProperty("os.name").toLowerCase(),
                System.getProperty("os.arch"));
        send(ex, 200, "text/html; charset=utf-8", html);
    }

    private static void send(HttpExchange ex, int status, String type, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().set("Content-Type", type);
        ex.sendResponseHeaders(status, bytes.length);
        try (OutputStream os = ex.getResponseBody()) {
            os.write(bytes);
        }
    }
}

import { useState, version } from "react";

export default function App() {
  const [clicks, setClicks] = useState(0);

  return (
    <main>
      <h1>Hello World from React</h1>
      <p>
        A Vite build of a React app. The node stage compiled it to static files,
        and nginx is serving them from inside a Docker container.
      </p>
      <table>
        <tbody>
          <tr><td>React</td><td>{version}</td></tr>
          <tr><td>Rendered</td><td>in your browser, by JavaScript</td></tr>
          <tr><td>Served by</td><td>nginx 1.30 on Alpine</td></tr>
        </tbody>
      </table>
      <button onClick={() => setClicks((c) => c + 1)}>
        Clicked {clicks} {clicks === 1 ? "time" : "times"}
      </button>
      <footer>Built by Pratyush Mohanty (Roll No. 24BCS10238)</footer>
    </main>
  );
}

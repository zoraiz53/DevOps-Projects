import { FormEvent, useEffect, useState } from "react";
import { AppRole, AuthSession, getStoredSession, login, logout, storeSession } from "./auth";

type DocumentStatus = "queued" | "in_review" | "approved" | "rejected" | "processing_failed";
type Priority = "low" | "medium" | "high";
type Screen = "login" | "employee" | "manager";

type HistoryEvent = {
  timestamp: string;
  type: string;
  message: string;
  actor?: string | null;
};

type DocumentRecord = {
  id: string;
  title: string;
  file_name: string;
  content_type: string;
  size_bytes: number;
  uploaded_by: string;
  department: string;
  priority: Priority;
  tags: string[];
  notes: string;
  status: DocumentStatus;
  storage_key: string;
  storage_location: string;
  reviewer?: string | null;
  decision_comment?: string | null;
  created_at: string;
  updated_at: string;
  history: HistoryEvent[];
};

type Summary = {
  total_documents: number;
  status_counts: Record<string, number>;
  department_counts: Record<string, number>;
  priority_counts: Record<string, number>;
};

type CurrentUser = {
  username: string;
  email?: string | null;
  name: string;
  groups: AppRole[];
  token_use: string;
};

const API_BASE_URL = window.__APP_CONFIG__?.API_BASE_URL ?? "http://localhost:8000";
const COGNITO_REGION = window.__APP_CONFIG__?.COGNITO_REGION ?? "";
const COGNITO_USER_POOL_ID = window.__APP_CONFIG__?.COGNITO_USER_POOL_ID ?? "";
const COGNITO_APP_CLIENT_ID = window.__APP_CONFIG__?.COGNITO_APP_CLIENT_ID ?? "";

const initialUploadState = {
  title: "",
  department: "General",
  priority: "medium" as Priority,
  tags: "",
  notes: "",
};

const initialDecisionState = {
  note: "",
};

const statusTone: Record<DocumentStatus, string> = {
  queued: "gold",
  in_review: "blue",
  approved: "green",
  rejected: "red",
  processing_failed: "gray",
};

function formatDate(value: string) {
  return new Date(value).toLocaleString();
}

function formatBytes(bytes: number) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

async function fetchJson<T>(path: string, session: AuthSession, options?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      ...(options?.headers ?? {}),
      Authorization: `Bearer ${session.accessToken}`,
    },
  });

  if (!response.ok) {
    const raw = await response.text();
    try {
      const parsed = JSON.parse(raw) as { detail?: string };
      if (parsed.detail) {
        return Promise.reject(new Error(parsed.detail));
      }
    } catch {
      throw new Error(raw || "Request failed");
    }
    throw new Error("Request failed");
  }

  return response.json() as Promise<T>;
}

function getDefaultScreen(session: AuthSession | null): Screen {
  if (!session) return "login";
  if (session.groups.includes("manager")) return "manager";
  return "employee";
}

function authConfigReady() {
  return Boolean(COGNITO_REGION && COGNITO_USER_POOL_ID && COGNITO_APP_CLIENT_ID);
}

export default function App() {
  const [session, setSession] = useState<AuthSession | null>(() => getStoredSession());
  const [currentUser, setCurrentUser] = useState<CurrentUser | null>(null);
  const [screen, setScreen] = useState<Screen>(() => getDefaultScreen(getStoredSession()));
  const [documents, setDocuments] = useState<DocumentRecord[]>([]);
  const [summary, setSummary] = useState<Summary | null>(null);
  const [selectedDocumentId, setSelectedDocumentId] = useState<string | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [feedback, setFeedback] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [departmentFilter, setDepartmentFilter] = useState("all");
  const [uploadState, setUploadState] = useState(initialUploadState);
  const [decisionState, setDecisionState] = useState(initialDecisionState);
  const [loginState, setLoginState] = useState({
    email: "",
    password: "",
  });

  const selectedDocument =
    documents.find((document) => document.id === selectedDocumentId) ?? documents[0] ?? null;

  const visibleDocuments = documents.filter((document) => {
    const matchesSearch =
      search.trim().length === 0 ||
      [document.title, document.file_name, document.uploaded_by, document.department]
        .join(" ")
        .toLowerCase()
        .includes(search.toLowerCase());
    const matchesStatus = statusFilter === "all" || document.status === statusFilter;
    const matchesDepartment =
      departmentFilter === "all" || document.department === departmentFilter;
    return matchesSearch && matchesStatus && matchesDepartment;
  });

  const departments = Array.from(new Set(documents.map((document) => document.department))).sort();
  const isManager = session?.groups.includes("manager") ?? false;

  useEffect(() => {
    if (!session) {
      setCurrentUser(null);
      setDocuments([]);
      setSummary(null);
      return;
    }

    void loadProtectedData(session);
  }, [session]);

  async function loadProtectedData(activeSession: AuthSession) {
    setIsLoading(true);
    try {
      const [userResponse, documentsResponse, summaryResponse] = await Promise.all([
        fetchJson<CurrentUser>("/me", activeSession),
        fetchJson<DocumentRecord[]>("/documents", activeSession),
        fetchJson<Summary>("/dashboard/summary", activeSession),
      ]);
      setCurrentUser(userResponse);
      setDocuments(documentsResponse);
      setSummary(summaryResponse);
      setSelectedDocumentId((current) => current ?? documentsResponse[0]?.id ?? null);
      setFeedback("");
      const nextScreen = userResponse.groups.includes("manager") ? "manager" : "employee";
      setScreen(nextScreen);
    } catch (error) {
      storeSession(null);
      setSession(null);
      setFeedback(error instanceof Error ? error.message : "Unable to load protected data.");
      setScreen("login");
    } finally {
      setIsLoading(false);
    }
  }

  async function handleLogin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    try {
      const nextSession = await login(loginState.email, loginState.password);
      setSession(nextSession);
      setFeedback("Signed in successfully.");
    } catch (error) {
      setFeedback(error instanceof Error ? error.message : "Login failed.");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleUpload(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!session) return;
    if (!selectedFile) {
      setFeedback("Choose a file before uploading.");
      return;
    }

    const formData = new FormData();
    formData.append("file", selectedFile);
    Object.entries(uploadState).forEach(([key, value]) => formData.append(key, value));

    setIsSubmitting(true);
    try {
      const created = await fetchJson<DocumentRecord>("/documents/upload", session, {
        method: "POST",
        body: formData,
      });
      setUploadState(initialUploadState);
      setSelectedFile(null);
      setSelectedDocumentId(created.id);
      setFeedback("Document uploaded and queued successfully.");
      await loadProtectedData(session);
    } catch (error) {
      setFeedback(error instanceof Error ? error.message : "Upload failed.");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleDecision(action: "approve" | "reject") {
    if (!session || !selectedDocument) return;

    setIsSubmitting(true);
    try {
      await fetchJson<DocumentRecord>(`/documents/${selectedDocument.id}/${action}`, session, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(decisionState),
      });
      setDecisionState(initialDecisionState);
      setFeedback(`Document ${action}d successfully.`);
      await loadProtectedData(session);
    } catch (error) {
      setFeedback(error instanceof Error ? error.message : `Unable to ${action} the document.`);
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleRetry() {
    if (!session || !selectedDocument) return;

    setIsSubmitting(true);
    try {
      await fetchJson<DocumentRecord>(`/documents/${selectedDocument.id}/retry`, session, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(decisionState),
      });
      setFeedback("Document was re-queued for processing.");
      await loadProtectedData(session);
    } catch (error) {
      setFeedback(error instanceof Error ? error.message : "Retry failed.");
    } finally {
      setIsSubmitting(false);
    }
  }

  function handleLogout() {
    logout();
    setSession(null);
    setCurrentUser(null);
    setScreen("login");
    setFeedback("Signed out.");
  }

  function renderLoginCard() {
    if (!authConfigReady()) {
      return (
        <div className="panel auth-card">
          <h1>Configure Cognito first</h1>
          <p className="muted-copy">
            Add `COGNITO_REGION`, `COGNITO_USER_POOL_ID`, and `COGNITO_APP_CLIENT_ID` before
            testing login.
          </p>
        </div>
      );
    }

    return (
      <div className="panel auth-card">
        <h1>Sign in</h1>
        <p className="muted-copy">Use your internal Cognito account to access this app.</p>
        <form className="stack" onSubmit={handleLogin}>
          <label>
            <span>Email</span>
            <input
              type="email"
              required
              value={loginState.email}
              onChange={(event) =>
                setLoginState((current) => ({ ...current, email: event.target.value }))
              }
            />
          </label>
          <label>
            <span>Password</span>
            <input
              type="password"
              required
              value={loginState.password}
              onChange={(event) =>
                setLoginState((current) => ({ ...current, password: event.target.value }))
              }
            />
          </label>
          <button className="primary-button" type="submit" disabled={isSubmitting}>
            {isSubmitting ? "Signing in..." : "Login"}
          </button>
        </form>
      </div>
    );
  }

  if (!session || screen === "login") {
    return (
      <div className="app-shell">
        <div className="ambient ambient-a" />
        <div className="ambient ambient-b" />
        <main className="page auth-page">
          <section className="hero auth-hero">
            <div>
              <p className="eyebrow">Internal Cognito Login</p>
              <h1>Secure document approvals with Cognito identities and groups.</h1>
              <p className="hero-copy">
                Accounts are created by admins in Cognito. FastAPI trusts only Cognito JWTs and
                checks group membership before allowing document actions.
              </p>
            </div>
            {renderLoginCard()}
          </section>
          {feedback ? <div className="feedback auth-feedback">{feedback}</div> : null}
        </main>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <div className="ambient ambient-a" />
      <div className="ambient ambient-b" />
      <main className="page">
        <section className="hero">
          <div>
            <p className="eyebrow">
              {isManager ? "Manager Workspace" : "Employee Workspace"}
            </p>
            <h1>Document approval with Cognito-backed access control.</h1>
            <p className="hero-copy">
              Signed in as <strong>{currentUser?.name ?? session.name}</strong>. Your role comes
              from the Cognito group inside the JWT token.
            </p>
          </div>
          <div className="hero-panel">
            <p>Current identity</p>
            <strong>{currentUser?.email ?? session.email ?? session.username}</strong>
            <span>Groups: {(currentUser?.groups ?? session.groups).join(", ") || "none"}</span>
            <div className="action-row">
              {isManager ? (
                <button className="ghost-button" type="button" onClick={() => setScreen("manager")}>
                  Manager page
                </button>
              ) : null}
              <button className="ghost-button" type="button" onClick={() => setScreen("employee")}>
                Employee page
              </button>
              <button className="danger-button" type="button" onClick={handleLogout}>
                Logout
              </button>
            </div>
          </div>
        </section>

        <section className="stats-grid">
          <article className="stat-card">
            <span>Total documents</span>
            <strong>{summary?.total_documents ?? 0}</strong>
            <small>{isManager ? "Full approval inventory" : "Your submitted documents"}</small>
          </article>
          <article className="stat-card">
            <span>Waiting attention</span>
            <strong>{(summary?.status_counts.queued ?? 0) + (summary?.status_counts.in_review ?? 0)}</strong>
            <small>Queued or actively being reviewed</small>
          </article>
          <article className="stat-card">
            <span>Approved</span>
            <strong>{summary?.status_counts.approved ?? 0}</strong>
            <small>Completed successfully</small>
          </article>
          <article className="stat-card">
            <span>High priority</span>
            <strong>{summary?.priority_counts.high ?? 0}</strong>
            <small>Items marked urgent</small>
          </article>
        </section>

        <section className="workspace">
          <aside className="sidebar">
            <div className="panel">
              <div className="panel-heading">
                <h2>Employee Upload</h2>
                <p>All authenticated internal users can upload documents with Cognito identity.</p>
              </div>
              <form className="stack" onSubmit={handleUpload}>
                <label>
                  <span>Document title</span>
                  <input
                    value={uploadState.title}
                    onChange={(event) =>
                      setUploadState((current) => ({ ...current, title: event.target.value }))
                    }
                    placeholder="Quarterly vendor agreement"
                  />
                </label>
                <div className="split">
                  <label>
                    <span>Department</span>
                    <input
                      value={uploadState.department}
                      onChange={(event) =>
                        setUploadState((current) => ({ ...current, department: event.target.value }))
                      }
                    />
                  </label>
                  <label>
                    <span>Priority</span>
                    <select
                      value={uploadState.priority}
                      onChange={(event) =>
                        setUploadState((current) => ({
                          ...current,
                          priority: event.target.value as Priority,
                        }))
                      }
                    >
                      <option value="low">Low</option>
                      <option value="medium">Medium</option>
                      <option value="high">High</option>
                    </select>
                  </label>
                </div>
                <label>
                  <span>Tags</span>
                  <input
                    value={uploadState.tags}
                    onChange={(event) =>
                      setUploadState((current) => ({ ...current, tags: event.target.value }))
                    }
                    placeholder="contract, finance, urgent"
                  />
                </label>
                <label>
                  <span>Notes</span>
                  <textarea
                    rows={4}
                    value={uploadState.notes}
                    onChange={(event) =>
                      setUploadState((current) => ({ ...current, notes: event.target.value }))
                    }
                    placeholder="Anything reviewers should know"
                  />
                </label>
                <label className="file-input">
                  <span>Choose file</span>
                  <input
                    type="file"
                    onChange={(event) => setSelectedFile(event.target.files?.[0] ?? null)}
                  />
                  <small>{selectedFile ? selectedFile.name : "No file selected yet."}</small>
                </label>
                <button className="primary-button" type="submit" disabled={isSubmitting}>
                  {isSubmitting ? "Uploading..." : "Upload and Queue"}
                </button>
              </form>
            </div>

            <div className="panel">
              <div className="panel-heading">
                <h2>Cognito Notes</h2>
                <p>What matters operationally.</p>
              </div>
              <ul className="plain-list">
                <li>
                  <strong>User Pool</strong> stores internal users and passwords.
                </li>
                <li>
                  <strong>Groups</strong> decide who is a manager or employee.
                </li>
                <li>
                  <strong>JWTs</strong> are sent to FastAPI in the `Authorization` header.
                </li>
                <li>
                  <strong>FastAPI</strong> verifies JWTs using Cognito public keys.
                </li>
              </ul>
            </div>
          </aside>

          <section className="main-content">
            <div className="panel">
              <div className="toolbar">
                <div>
                  <h2>{isManager ? "Manager Review Queue" : "Employee Document View"}</h2>
                  <p>
                    {isManager
                      ? "Managers can review every document and take approval actions."
                      : "Employees only see their own submissions from the backend."}
                  </p>
                </div>
                <button
                  className="ghost-button"
                  onClick={() => session && void loadProtectedData(session)}
                  disabled={isLoading}
                >
                  Refresh
                </button>
              </div>

              <div className="filters">
                <input
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                  placeholder="Search title, file, uploader..."
                />
                <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
                  <option value="all">All statuses</option>
                  <option value="queued">Queued</option>
                  <option value="in_review">In review</option>
                  <option value="approved">Approved</option>
                  <option value="rejected">Rejected</option>
                  <option value="processing_failed">Failed</option>
                </select>
                <select
                  value={departmentFilter}
                  onChange={(event) => setDepartmentFilter(event.target.value)}
                >
                  <option value="all">All departments</option>
                  {departments.map((department) => (
                    <option key={department} value={department}>
                      {department}
                    </option>
                  ))}
                </select>
              </div>

              {feedback ? <div className="feedback">{feedback}</div> : null}

              <div className="document-grid">
                <div className="document-list">
                  {isLoading ? <p className="empty-state">Loading documents...</p> : null}
                  {!isLoading && visibleDocuments.length === 0 ? (
                    <p className="empty-state">No documents match your current filters.</p>
                  ) : null}
                  {visibleDocuments.map((document) => (
                    <button
                      key={document.id}
                      type="button"
                      className={`document-card ${
                        selectedDocument?.id === document.id ? "document-card-active" : ""
                      }`}
                      onClick={() => setSelectedDocumentId(document.id)}
                    >
                      <div className="document-card-top">
                        <span className={`badge badge-${statusTone[document.status]}`}>{document.status}</span>
                        <span className="priority-pill">{document.priority}</span>
                      </div>
                      <h3>{document.title}</h3>
                      <p>{document.file_name}</p>
                      <div className="document-meta">
                        <span>{document.department}</span>
                        <span>{document.uploaded_by}</span>
                        <span>{formatBytes(document.size_bytes)}</span>
                      </div>
                    </button>
                  ))}
                </div>

                <div className="detail-panel">
                  {selectedDocument ? (
                    <>
                      <div className="detail-header">
                        <div>
                          <span className={`badge badge-${statusTone[selectedDocument.status]}`}>
                            {selectedDocument.status}
                          </span>
                          <h2>{selectedDocument.title}</h2>
                          <p>{selectedDocument.file_name}</p>
                        </div>
                        <div className="detail-summary">
                          <span>{selectedDocument.department}</span>
                          <span>{formatDate(selectedDocument.updated_at)}</span>
                        </div>
                      </div>

                      <div className="detail-section-grid">
                        <div className="panel subtle-panel">
                          <h3>Details</h3>
                          <dl className="detail-list">
                            <div>
                              <dt>Uploaded by</dt>
                              <dd>{selectedDocument.uploaded_by}</dd>
                            </div>
                            <div>
                              <dt>Storage</dt>
                              <dd>{selectedDocument.storage_location}</dd>
                            </div>
                            <div>
                              <dt>Priority</dt>
                              <dd>{selectedDocument.priority}</dd>
                            </div>
                            <div>
                              <dt>Reviewer</dt>
                              <dd>{selectedDocument.reviewer ?? "Not assigned yet"}</dd>
                            </div>
                          </dl>
                          <p className="notes-box">{selectedDocument.notes || "No notes added."}</p>
                          <div className="tag-row">
                            {selectedDocument.tags.length > 0 ? (
                              selectedDocument.tags.map((tag) => (
                                <span key={tag} className="tag">
                                  {tag}
                                </span>
                              ))
                            ) : (
                              <span className="muted-copy">No tags</span>
                            )}
                          </div>
                        </div>

                        {isManager ? (
                          <div className="panel subtle-panel">
                            <h3>Manager Actions</h3>
                            <div className="stack">
                              <label>
                                <span>Decision note</span>
                                <textarea
                                  rows={4}
                                  value={decisionState.note}
                                  onChange={(event) =>
                                    setDecisionState({
                                      note: event.target.value,
                                    })
                                  }
                                  placeholder="Add review notes or retry context"
                                />
                              </label>
                              <div className="action-row">
                                <button
                                  className="primary-button"
                                  onClick={() => void handleDecision("approve")}
                                  disabled={isSubmitting}
                                >
                                  Approve
                                </button>
                                <button
                                  className="danger-button"
                                  onClick={() => void handleDecision("reject")}
                                  disabled={isSubmitting}
                                >
                                  Reject
                                </button>
                                <button
                                  className="ghost-button"
                                  onClick={() => void handleRetry()}
                                  disabled={isSubmitting}
                                >
                                  Retry Queue
                                </button>
                              </div>
                            </div>
                          </div>
                        ) : (
                          <div className="panel subtle-panel">
                            <h3>Employee Access</h3>
                            <p className="muted-copy">
                              Employees can upload and monitor their own documents. Approval actions
                              are blocked by both the frontend and FastAPI.
                            </p>
                          </div>
                        )}
                      </div>

                      <div className="panel subtle-panel">
                        <h3>Approval Timeline</h3>
                        <div className="timeline">
                          {selectedDocument.history
                            .slice()
                            .reverse()
                            .map((entry, index) => (
                              <div key={`${entry.timestamp}-${index}`} className="timeline-item">
                                <div className="timeline-dot" />
                                <div>
                                  <strong>{entry.type.split("_").join(" ")}</strong>
                                  <p>{entry.message}</p>
                                  <small>
                                    {entry.actor ? `${entry.actor} • ` : ""}
                                    {formatDate(entry.timestamp)}
                                  </small>
                                </div>
                              </div>
                            ))}
                        </div>
                      </div>
                    </>
                  ) : (
                    <p className="empty-state">Select a document to see details.</p>
                  )}
                </div>
              </div>
            </div>
          </section>
        </section>
      </main>
    </div>
  );
}

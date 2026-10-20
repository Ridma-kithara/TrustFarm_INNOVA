const colors = { Green: "#2e9e5b", Amber: "#e0a100", Red: "#d64545" } as const;

export default function TrustBadge({ level, score }: { level?: keyof typeof colors | null; score?: number }) {
  if (!level) return <span className="badge" style={{ background: "#888" }}>No data</span>;
  return (
    <span className="badge" style={{ background: colors[level] }}>
      Data Trust: {level}{score !== undefined ? ` (${score.toFixed(0)})` : ""}
    </span>
  );
}

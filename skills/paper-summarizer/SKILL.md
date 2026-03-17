---
name: paper-summarizer
description: Generate structured key takeaways from academic papers, patents, or technical documents. Use when asked to summarize papers, extract contributions, or create TLDRs.
allowed-tools: Read, Write, Task
argument-hint: [PDF file path(s)]
tags: [research, documentation]
version: 1.0.0
---

# Paper Summarizer

Generate structured key takeaways from academic papers, patents, or technical documents. The audience is researchers who want a quick, precise understanding — not a vague rewording of the abstract.

## Usage

```
/paper-summarizer paper.pdf
/paper-summarizer paper1.pdf paper2.pdf paper3.pdf
```

## Input

One or more PDF file paths (or paper text directly). Read each PDF — the first 10 pages usually contain everything needed (abstract, introduction, main results, methodology).

## Output Format

For each paper, produce a structured summary with three sections:

```
**Problem:** [1 sentence]
**Key result:** [1-2 sentences]
**Method:** [1 sentence]
```

### Section Guidelines

**Problem** — What question, gap, or challenge does the paper address? Frame it as a question or "how to" statement. Be specific: "Can the structured inverse eigenvalue problem be extended to infinite graphs?" is better than "This paper studies inverse eigenvalue problems."

**Key result** — The main theorem, finding, or contribution. Include precise statements (mathematical, empirical with effect sizes, or system capabilities for patents). If there's a surprising corollary or implication, include it.

**Method** — The technique, approach, or experimental design in one sentence. Name specific tools, algorithms, or protocols. "Implicit Function Theorem applied to a parametrized family of matrices" is better than "mathematical proof techniques."

## Style

- **Be precise.** Use the paper's own terminology. If the paper proves a theorem about "TU-subgraphs," say "TU-subgraphs," not "certain graph structures."
- **Be concise.** Each section is 1-2 sentences maximum. The entire takeaway should fit in a short paragraph.
- **Use math notation** where it helps clarity. Wrap LaTeX in `\(...\)` for inline math.
- **Write for the paper's audience.** A matrix theory paper gets matrix theory language. A neuroscience paper gets neuroscience language. But aim for the clearest possible expression — a general scientist in an adjacent field should follow the gist.
- **Don't rehash the abstract.** Your takeaway should be a distillation that's faster to read and more structured.

## Presenting Results

Return results as a numbered list:

```
1. **[Paper title]** (filename.pdf)

   **Problem:** ...
   **Key result:** ...
   **Method:** ...
```

If the user wants output in a specific format (JSON, markdown table, HTML, etc.), adapt — the three-section structure stays the same, only the container changes.

## Edge Cases

- **Patents**: "Key result" = main invention/capability. "Method" = technical approach of the system.
- **Survey papers**: "Key result" = main insight or taxonomy. "Method" = survey methodology (systematic review, meta-analysis, etc.).
- **Work in progress / incomplete PDFs**: Summarize what's available. Flag if key sections are missing.
- **Non-English papers**: Do your best with available content. Note the language limitation.

## Batch Processing

When given multiple papers, process them independently. If the user asks for parallelism, use the Task tool to spawn subagents — one per paper or per batch of 3-4 papers.

---

*Generalized from: k1monfared.github.io*

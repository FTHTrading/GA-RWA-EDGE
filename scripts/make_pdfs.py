#!/usr/bin/env python3
"""Render GA-EDGE-2 markdown docs into branded, letter-format PDFs under docs/downloads/.
Institutional style: obsidian header band, silver rule, Helvetica, footer with doc id.
Simple md subset: #/##/### headings, - bullets, 1. numbered, **bold** inline, plain paragraphs.
"""
import os, re, glob
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.platypus import BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer

OBSIDIAN = colors.HexColor("#14161a")
STEEL = colors.HexColor("#5b6169")
LINE = colors.HexColor("#c8ccd0")

DOCS = [
    ("docs/02-georgia-energy-playbook/README.md", "georgia-energy-playbook.pdf", "Georgia Energy Playbook", "GA-EDGE-2 · 🟩 Energy"),
    ("epc/contract-checklists/modular-epc-12-clause-review.md", "modular-epc-12-clause-review.pdf", "Modular EPC — 12-Clause Contract Review", "GA-EDGE-2 · 🟧 EPC"),
    ("templates/ppa-diligence-pack/ppa-12-item-scored.md", "ppa-12-item-scored-diligence.pdf", "PPA / Offtake — 12-Item Scored Diligence", "GA-EDGE-2 · ⬛ Templates"),
    ("site/rural-qrof-screening/checklist.md", "rural-qrof-site-screen.pdf", "Rural QROF Site Screen", "GA-EDGE-2 · 🟨 Site"),
    ("templates/commissioning-certificates/fat-sat-ist-template.md", "commissioning-certificate-fat-sat-ist.pdf", "Commissioning Certificate — FAT / SAT / IST", "GA-EDGE-2 · ⬛ Templates"),
    ("operations/pue-carbon-metrics/metrics-spec.md", "operational-metrics-spec.pdf", "Operational Metrics Specification", "GA-EDGE-2 · 🟥 Operations"),
    ("integration/reserve-proof-schemas/README.md", "rwa-rails-integration-schemas.pdf", "RWA Rails Integration Schemas", "GA-EDGE-2 · 🟪 Integration"),
    ("docs/client-requirements-guide.md", "client-requirements-and-diligence-guide.pdf", "Client Requirements & Diligence Guide", "FTH Trading · LD Capital"),
]

def styles():
    ss = getSampleStyleSheet()
    ss.add(ParagraphStyle("H1x", parent=ss["Heading1"], fontName="Helvetica-Bold", fontSize=16, textColor=OBSIDIAN, spaceBefore=14, spaceAfter=6))
    ss.add(ParagraphStyle("H2x", parent=ss["Heading2"], fontName="Helvetica-Bold", fontSize=12.5, textColor=OBSIDIAN, spaceBefore=12, spaceAfter=4))
    ss.add(ParagraphStyle("H3x", parent=ss["Heading3"], fontName="Helvetica-Bold", fontSize=11, textColor=STEEL, spaceBefore=10, spaceAfter=3))
    ss.add(ParagraphStyle("Bodyx", parent=ss["Normal"], fontName="Helvetica", fontSize=9.5, leading=13.5, textColor=OBSIDIAN, spaceAfter=4))
    ss.add(ParagraphStyle("Bullx", parent=ss["Bodyx"], leftIndent=14, bulletIndent=4, spaceAfter=3))
    return ss

def inline(md):
    t = md.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"`(.+?)`", r"<font face='Courier' size='8.5'>\1</font>", t)
    # strip emoji color squares that lack glyphs in Helvetica
    t = re.sub(r"[\U0001F7E6\U0001F7E9\U0001F7E8\U0001F7E7\U0001F7E5\U0001F7EA⬛\U0001F9ED\U0001F680\U0001F4D0\U0001F517\U0001F9EE]", "", t)
    return t.strip()

def md_to_story(path, ss):
    story = []
    for raw in open(path, encoding="utf-8").read().splitlines():
        line = raw.rstrip()
        if not line.strip():
            continue
        if line.startswith("### "):
            story.append(Paragraph(inline(line[4:]), ss["H3x"]))
        elif line.startswith("## "):
            story.append(Paragraph(inline(line[3:]), ss["H2x"]))
        elif line.startswith("# "):
            story.append(Paragraph(inline(line[2:]), ss["H1x"]))
        elif re.match(r"^\s*[-*] ", line):
            story.append(Paragraph(inline(re.sub(r"^\s*[-*] ", "", line)), ss["Bullx"], bulletText="–"))
        elif re.match(r"^\s*\d+[\.\)] ", line):
            num = re.match(r"^\s*(\d+)[\.\)] ", line).group(1)
            story.append(Paragraph(inline(re.sub(r"^\s*\d+[\.\)] ", "", line)), ss["Bullx"], bulletText=num + "."))
        elif line.startswith("[ ]") or line.startswith("[x]"):
            story.append(Paragraph("&#9744; " + inline(line[3:]), ss["Bullx"]))
        else:
            story.append(Paragraph(inline(line), ss["Bodyx"]))
    return story

def build(src, out, title, band, ss):
    def decorate(canv, doc):
        w, h = letter
        canv.saveState()
        canv.setFillColor(OBSIDIAN)
        canv.rect(0, h - 0.62 * inch, w, 0.62 * inch, stroke=0, fill=1)
        canv.setFillColor(colors.HexColor("#e6e8ea"))
        canv.setFont("Helvetica-Bold", 10.5)
        canv.drawString(0.7 * inch, h - 0.40 * inch, title)
        canv.setFillColor(colors.HexColor("#9096a0"))
        canv.setFont("Helvetica", 7.5)
        canv.drawRightString(w - 0.7 * inch, h - 0.40 * inch, re.sub(r"[^\x00-\x7f]+", "", band).strip())
        canv.setStrokeColor(LINE)
        canv.setLineWidth(0.6)
        canv.line(0.7 * inch, 0.55 * inch, w - 0.7 * inch, 0.55 * inch)
        canv.setFont("Helvetica", 7)
        canv.setFillColor(STEEL)
        canv.drawString(0.7 * inch, 0.4 * inch, "FTH Trading / Unykorn LLC - proprietary - not legal, tax, or investment advice")
        canv.drawRightString(w - 0.7 * inch, 0.4 * inch, f"{os.path.basename(out)}  ·  page {doc.page}")
        canv.restoreState()

    doc = BaseDocTemplate(out, pagesize=letter,
                          leftMargin=0.7 * inch, rightMargin=0.7 * inch,
                          topMargin=0.9 * inch, bottomMargin=0.75 * inch, title=title)
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="f")
    doc.addPageTemplates([PageTemplate(id="p", frames=[frame], onPage=decorate)])
    doc.build(md_to_story(src, ss))

def main():
    os.makedirs("docs/downloads", exist_ok=True)
    ss = styles()
    for src, name, title, band in DOCS:
        out = os.path.join("docs/downloads", name)
        build(src, out, title, band, ss)
        print(f"built {out}")

if __name__ == "__main__":
    main()

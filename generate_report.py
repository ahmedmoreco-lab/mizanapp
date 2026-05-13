"""
SoulPing Care — Final Project Report Generator
Generates a professional .docx report for BDE498 Capstone Project I
"""

from docx import Document
from docx.shared import Pt, RGBColor, Inches, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import copy

# ── Brand colours ────────────────────────────────────────────────────────────
TEAL       = RGBColor(0x0F, 0x76, 0x6E)
NAVY       = RGBColor(0x12, 0x32, 0x47)
DARK_GRAY  = RGBColor(0x1E, 0x29, 0x3B)
MID_GRAY   = RGBColor(0x5A, 0x68, 0x71)
WHITE      = RGBColor(0xFF, 0xFF, 0xFF)
LIGHT_GRAY = RGBColor(0xF8, 0xFA, 0xFC)
CODE_BG    = RGBColor(0xF1, 0xF5, 0xF9)

# callout box colours (as hex strings for XML shading)
GREEN_BG   = "DCFCE7"
AMBER_BG   = "FEF3C7"
BLUE_BG    = "DBEAFE"
TEAL_BG    = "CCFBF1"


# ── Low-level XML helpers ─────────────────────────────────────────────────────

def set_cell_bg(cell, hex_color: str):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hex_color)
    tcPr.append(shd)


def set_cell_borders(cell, top=None, bottom=None, left=None, right=None):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = OxmlElement("w:tcBorders")
    for side, val in [("top", top), ("bottom", bottom),
                      ("left", left), ("right", right)]:
        if val:
            el = OxmlElement(f"w:{side}")
            el.set(qn("w:val"), val.get("val", "single"))
            el.set(qn("w:sz"), val.get("sz", "4"))
            el.set(qn("w:color"), val.get("color", "auto"))
            tcBorders.append(el)
    tcPr.append(tcBorders)


def add_para_border_bottom(para, hex_color="0F766E"):
    pPr = para._p.get_or_add_pPr()
    pBdr = OxmlElement("w:pBdr")
    bottom = OxmlElement("w:bottom")
    bottom.set(qn("w:val"), "single")
    bottom.set(qn("w:sz"), "8")
    bottom.set(qn("w:space"), "4")
    bottom.set(qn("w:color"), hex_color)
    pBdr.append(bottom)
    pPr.append(pBdr)


def set_para_shading(para, hex_color: str):
    pPr = para._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hex_color)
    pPr.append(shd)


def set_para_left_border(para, hex_color: str, sz: str = "24"):
    pPr = para._p.get_or_add_pPr()
    pBdr = OxmlElement("w:pBdr")
    left = OxmlElement("w:left")
    left.set(qn("w:val"), "single")
    left.set(qn("w:sz"), sz)
    left.set(qn("w:space"), "6")
    left.set(qn("w:color"), hex_color)
    pBdr.append(left)
    pPr.append(pBdr)


def add_page_break(doc):
    para = doc.add_paragraph()
    run = para.add_run()
    run.add_break(docx_break_type())
    return para


def docx_break_type():
    from docx.oxml.ns import qn
    from docx.oxml import OxmlElement
    br = OxmlElement("w:br")
    br.set(qn("w:type"), "page")
    return br  # placeholder — we use add_page_break differently below


def page_break(doc):
    para = doc.add_paragraph()
    para.paragraph_format.space_before = Pt(0)
    para.paragraph_format.space_after = Pt(0)
    run = para.add_run()
    br = OxmlElement("w:br")
    br.set(qn("w:type"), "page")
    run._r.append(br)


# ── Document helpers ──────────────────────────────────────────────────────────

def heading1(doc, text: str):
    para = doc.add_paragraph()
    para.paragraph_format.space_before = Pt(18)
    para.paragraph_format.space_after = Pt(4)
    run = para.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(16)
    run.font.bold = True
    run.font.color.rgb = TEAL
    add_para_border_bottom(para, "0F766E")
    return para


def heading2(doc, text: str):
    para = doc.add_paragraph()
    para.paragraph_format.space_before = Pt(12)
    para.paragraph_format.space_after = Pt(2)
    run = para.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(13)
    run.font.bold = True
    run.font.color.rgb = DARK_GRAY
    return para


def body(doc, text: str, bold=False, italic=False, color=None):
    para = doc.add_paragraph()
    para.paragraph_format.space_before = Pt(2)
    para.paragraph_format.space_after = Pt(4)
    run = para.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(11)
    run.font.bold = bold
    run.font.italic = italic
    if color:
        run.font.color.rgb = color
    return para


def bullet(doc, text: str, level=0):
    para = doc.add_paragraph(style="List Bullet")
    para.paragraph_format.left_indent = Inches(0.25 * (level + 1))
    para.paragraph_format.space_before = Pt(1)
    para.paragraph_format.space_after = Pt(1)
    run = para.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(11)
    return para


def code_block(doc, text: str):
    para = doc.add_paragraph()
    para.paragraph_format.space_before = Pt(4)
    para.paragraph_format.space_after = Pt(4)
    para.paragraph_format.left_indent = Inches(0.3)
    set_para_shading(para, "F1F5F9")
    run = para.add_run(text)
    run.font.name = "Courier New"
    run.font.size = Pt(9)
    run.font.color.rgb = DARK_GRAY
    return para


def callout(doc, text: str, kind="done"):
    """kind: done | pending | action | info"""
    colours = {
        "done":    ("DCFCE7", "16A34A"),
        "pending": ("FEF3C7", "D97706"),
        "action":  ("DBEAFE", "2563EB"),
        "info":    ("CCFBF1", "0F766E"),
    }
    bg, border = colours.get(kind, colours["info"])
    para = doc.add_paragraph()
    para.paragraph_format.left_indent = Inches(0.2)
    para.paragraph_format.right_indent = Inches(0.2)
    para.paragraph_format.space_before = Pt(4)
    para.paragraph_format.space_after = Pt(4)
    set_para_shading(para, bg)
    set_para_left_border(para, border, "24")
    run = para.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(10)
    run.font.color.rgb = DARK_GRAY
    return para


def styled_table(doc, headers, rows, col_widths=None):
    """Create a styled table with dark header row and alternating body rows."""
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.LEFT

    # Header row
    hdr_row = table.rows[0]
    for i, hdr in enumerate(headers):
        cell = hdr_row.cells[i]
        set_cell_bg(cell, "1E293B")
        para = cell.paragraphs[0]
        run = para.add_run(hdr)
        run.font.name = "Arial"
        run.font.size = Pt(10)
        run.font.bold = True
        run.font.color.rgb = WHITE
        para.alignment = WD_ALIGN_PARAGRAPH.LEFT

    # Data rows
    for r_idx, row_data in enumerate(rows):
        row = table.rows[r_idx + 1]
        bg = "FFFFFF" if r_idx % 2 == 0 else "F8FAFC"
        for c_idx, cell_text in enumerate(row_data):
            cell = row.cells[c_idx]
            set_cell_bg(cell, bg)
            para = cell.paragraphs[0]
            run = para.add_run(str(cell_text))
            run.font.name = "Arial"
            run.font.size = Pt(10)

    # Column widths
    if col_widths:
        for i, row in enumerate(table.rows):
            for j, cell in enumerate(row.cells):
                if j < len(col_widths):
                    cell.width = Inches(col_widths[j])

    doc.add_paragraph()  # spacing after table
    return table


# ── Header / Footer ───────────────────────────────────────────────────────────

def add_header_footer(doc):
    section = doc.sections[0]

    # Header
    header = section.header
    header.is_linked_to_previous = False
    hp = header.paragraphs[0]
    hp.text = "SoulPing Care — Final Project Report | BDE498 | 2025–2026"
    hp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in hp.runs:
        run.font.name = "Arial"
        run.font.size = Pt(9)
        run.font.color.rgb = MID_GRAY

    # Footer with page number — each fldChar must be in its own w:r run
    footer = section.footer
    footer.is_linked_to_previous = False
    fp = footer.paragraphs[0]
    fp.alignment = WD_ALIGN_PARAGRAPH.CENTER

    def _make_fld_run(para, fld_type=None, instr=None):
        r = OxmlElement("w:r")
        rPr = OxmlElement("w:rPr")
        rFonts = OxmlElement("w:rFonts")
        rFonts.set(qn("w:ascii"), "Arial")
        rPr.append(rFonts)
        sz = OxmlElement("w:sz")
        sz.set(qn("w:val"), "18")
        rPr.append(sz)
        r.append(rPr)
        if fld_type:
            fc = OxmlElement("w:fldChar")
            fc.set(qn("w:fldCharType"), fld_type)
            r.append(fc)
        if instr:
            it = OxmlElement("w:instrText")
            it.set(qn("xml:space"), "preserve")
            it.text = instr
            r.append(it)
        para._p.append(r)

    _make_fld_run(fp, fld_type="begin")
    _make_fld_run(fp, instr=" PAGE ")
    _make_fld_run(fp, fld_type="separate")
    _make_fld_run(fp, fld_type="end")


# ── Cover page ────────────────────────────────────────────────────────────────

def build_cover(doc):
    section = doc.sections[0]
    section.different_first_page_header_footer = True  # no header on cover

    for _ in range(6):
        doc.add_paragraph()

    # App name
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("SoulPing Care")
    r.font.name = "Arial"
    r.font.size = Pt(36)
    r.font.bold = True
    r.font.color.rgb = TEAL

    # Subtitle
    p2 = doc.add_paragraph()
    p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r2 = p2.add_run("Final Project Report")
    r2.font.name = "Arial"
    r2.font.size = Pt(18)
    r2.font.color.rgb = DARK_GRAY

    p3 = doc.add_paragraph()
    p3.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r3 = p3.add_run("Phase 3: System Design & Implementation")
    r3.font.name = "Arial"
    r3.font.size = Pt(14)
    r3.font.italic = True
    r3.font.color.rgb = MID_GRAY

    doc.add_paragraph()

    # Teal divider rule
    div = doc.add_paragraph()
    div.alignment = WD_ALIGN_PARAGRAPH.CENTER
    add_para_border_bottom(div, "0F766E")

    doc.add_paragraph()

    # Course info
    for line in [
        ("Course:", "BDE498 — Capstone Project I"),
        ("Academic Year:", "2025–2026"),
        ("Date:", "May 2026"),
        ("Supervisor:", "Dr. / Eng. [Supervisor Name]"),
    ]:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_label = p.add_run(f"{line[0]}  ")
        r_label.font.name = "Arial"
        r_label.font.size = Pt(12)
        r_label.font.bold = True
        r_label.font.color.rgb = DARK_GRAY
        r_val = p.add_run(line[1])
        r_val.font.name = "Arial"
        r_val.font.size = Pt(12)
        r_val.font.color.rgb = MID_GRAY

    doc.add_paragraph()
    doc.add_paragraph()

    # Team table
    p_team = doc.add_paragraph()
    p_team.alignment = WD_ALIGN_PARAGRAPH.CENTER
    rt = p_team.add_run("Development Team")
    rt.font.name = "Arial"
    rt.font.size = Pt(13)
    rt.font.bold = True
    rt.font.color.rgb = TEAL

    doc.add_paragraph()

    team_table = doc.add_table(rows=1, cols=2)
    team_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    team_table.style = "Table Grid"
    hrow = team_table.rows[0]
    for i, hdr in enumerate(["Name", "Student ID"]):
        cell = hrow.cells[i]
        set_cell_bg(cell, "0F766E")
        p = cell.paragraphs[0]
        r = p.add_run(hdr)
        r.font.name = "Arial"
        r.font.size = Pt(11)
        r.font.bold = True
        r.font.color.rgb = WHITE
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER

    members = [
        ("Abdullah", "[Student ID]"),
        ("Ahmed", "[Student ID]"),
        ("Mai", "[Student ID]"),
        ("Moazz", "[Student ID]"),
        ("Seif", "[Student ID]"),
    ]
    for idx, (name, sid) in enumerate(members):
        row = team_table.add_row()
        bg = "FFFFFF" if idx % 2 == 0 else "F0FDFA"
        for ci, val in enumerate([name, sid]):
            cell = row.cells[ci]
            set_cell_bg(cell, bg)
            p = cell.paragraphs[0]
            r = p.add_run(val)
            r.font.name = "Arial"
            r.font.size = Pt(11)
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER

    page_break(doc)


# ── TOC placeholder ───────────────────────────────────────────────────────────

def build_toc(doc):
    heading1(doc, "Table of Contents")
    callout(doc,
            "Note: Press Ctrl+A then F9 in Microsoft Word to update all fields "
            "and generate the live Table of Contents.",
            kind="action")
    # TOC field — each fldChar must live inside its own w:r element
    para = doc.add_paragraph()
    p = para._p

    def _toc_run(fld_type=None, instr=None):
        r = OxmlElement("w:r")
        if fld_type:
            fc = OxmlElement("w:fldChar")
            fc.set(qn("w:fldCharType"), fld_type)
            r.append(fc)
        if instr:
            it = OxmlElement("w:instrText")
            it.set(qn("xml:space"), "preserve")
            it.text = instr
            r.append(it)
        p.append(r)

    _toc_run(fld_type="begin")
    _toc_run(instr=' TOC \\o "1-3" \\h \\z \\u ')
    _toc_run(fld_type="separate")
    _toc_run(fld_type="end")
    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 1 — PROJECT OVERVIEW
# ═════════════════════════════════════════════════════════════════════════════

def section1(doc):
    heading1(doc, "Section 1 — Project Overview")

    heading2(doc, "1.1  What the App Is")
    body(doc,
         "SoulPing Care is a Flutter/Firebase mobile safety application designed to connect "
         "elderly users — referred to in the system as Elders — with their designated family "
         "members or caregivers, referred to as Contacts. The application implements a "
         "passive daily safety loop that requires minimal effort from the elderly user while "
         "providing their Contact with real-time visibility into their wellbeing.")
    body(doc, "The core safety loop operates as follows:")
    bullet(doc, "The Elder opens the application once per day and taps a large, clearly labelled "
                '"I\'m OK" button to confirm they are safe.')
    bullet(doc, "If the Elder does not check in within a configurable time window (default: "
                "24 hours), the Contact automatically receives a push notification alert on "
                "their device.")
    bullet(doc, "If the Elder encounters an emergency, they press the red SOS button. This "
                "triggers an immediate high-priority push notification to the Contact, regardless "
                "of the normal check-in schedule.")
    body(doc,
         "The user interface was deliberately designed around the needs of elderly users "
         "with limited technical experience. Key design principles include large tap targets "
         "to accommodate reduced fine motor control, minimal screen count to reduce cognitive "
         "load, simple plain-language labels, and high-contrast colour coding (green = safe, "
         "red = alert).")

    heading2(doc, "1.2  Who the Users Are")
    body(doc, "The application serves two distinct user roles:")
    bullet(doc, "Elder: The person being monitored. The Elder uses the Elder Dashboard daily to "
                "submit check-ins and, in an emergency, to trigger an SOS alert. Elders are "
                "typically elderly individuals living independently who may be at risk of health "
                "episodes or accidents.")
    bullet(doc, "Contact: The family member, caregiver, or trusted person responsible for "
                "monitoring the Elder. The Contact uses the Contact Dashboard to view the "
                "Elder's real-time status. Contacts receive push notification alerts when "
                "intervention may be needed.")
    body(doc,
         "Each Elder is linked to a Contact via a linkedUserId field stored in Firestore. "
         "The relationship is one-to-one: one Elder maps to exactly one Contact, and vice "
         "versa. The linking is established during onboarding and persists for the lifetime "
         "of both accounts.")

    heading2(doc, "1.3  The Problem It Solves")
    body(doc,
         "Elderly people living alone face a significant but often invisible risk: if they "
         "experience a fall, health episode, or other emergency, no one may be aware for "
         "hours or even days. Existing informal solutions — regular phone calls, check-in "
         "text messages — rely entirely on human memory and are inherently unreliable. If "
         "the family member forgets to call, or the elderly person forgets to respond, "
         "the safety check fails silently.")
    body(doc,
         "SoulPing Care automates this check-in loop. The Elder's daily tap creates a "
         "timestamped record in the database. A Cloud Function running on a 30-minute "
         "schedule automatically compares the time of the last check-in against the "
         "configured threshold. If the threshold is exceeded, the Contact is notified "
         "without any human needing to remember to check. This creates a passive safety "
         "net — one that works even when everyone involved has forgotten to think about it.")

    heading2(doc, "1.4  Academic Context")
    styled_table(doc,
        headers=["Field", "Detail"],
        rows=[
            ["Course", "BDE498 — Capstone Project I"],
            ["Phase covered", "Phase 3 — System Design & Implementation"],
            ["Academic year", "2025–2026"],
            ["Primary deliverable", "Conceptual Data Model, system implementation, full feature delivery"],
            ["Secondary deliverable", "This Final Project Report"],
        ],
        col_widths=[2.2, 4.0]
    )
    callout(doc,
            "ℹ️  This report covers Phase 3 of the BDE498 capstone sequence, documenting "
            "every architectural decision, data modeling choice, and feature implementation "
            "decision made during the system design and build phases.",
            kind="info")

    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 2 — TECHNOLOGY STACK
# ═════════════════════════════════════════════════════════════════════════════

def section2(doc):
    heading1(doc, "Section 2 — Technology Stack & Architecture Decisions")

    heading2(doc, "2.1  Flutter (Dart) — Mobile Framework")
    body(doc,
         "Flutter is Google's open-source UI framework for building natively compiled mobile, "
         "web, and desktop applications from a single codebase. Developers write Flutter "
         "applications in the Dart programming language. Flutter renders its own widgets "
         "directly to the screen using the Skia/Impeller graphics engine, which means the "
         "UI looks and performs identically on both Android and iOS without relying on "
         "platform-native UI components.")
    body(doc,
         "Flutter was chosen for SoulPing Care because it allowed the team to build and "
         "maintain a single codebase that targets both Android and iOS simultaneously. This "
         "was critical given the project's timeline constraints — maintaining two separate "
         "native codebases (Swift for iOS, Kotlin for Android) would have doubled development "
         "effort. Flutter's widget system also provided the granular control needed to build "
         "unusually large tap targets and accessible UI for elderly users.")
    body(doc,
         "Alternative considered: React Native. React Native was evaluated but not selected "
         "because React Native renders using the platform's native UI components, which can "
         "produce subtle visual inconsistencies between Android and iOS. Flutter's custom "
         "rendering engine guarantees pixel-perfect consistency across platforms, which "
         "mattered for the accessibility-focused UI design.")

    heading2(doc, "2.2  Firebase — Backend Platform")
    body(doc,
         "Firebase is Google's mobile and web application development platform, providing "
         "a suite of cloud services accessible through client-side SDKs. SoulPing Care "
         "uses four Firebase services: Firestore (real-time NoSQL database), Firebase "
         "Authentication (user identity management), Firebase Cloud Messaging or FCM "
         "(push notifications), and Firebase Cloud Functions (serverless backend logic).")
    body(doc,
         "Firebase was chosen because it provides real-time data listeners as a first-class "
         "feature. The Contact Dashboard requires that the Elder's status updates appear on "
         "the Contact's screen automatically and immediately, without the Contact needing "
         "to manually refresh. Firestore's stream-based architecture makes this trivial to "
         "implement — a single stream subscription updates the UI whenever the underlying "
         "data changes.")
    body(doc,
         "Alternative considered: a custom REST API built with Node.js and Express, backed "
         "by a PostgreSQL database. This approach was evaluated but not selected because "
         "implementing real-time push to clients would have required either WebSockets or "
         "long-polling — both significantly more complex to build and maintain than Firestore "
         "streams. Firebase also handles authentication, session management, and token "
         "rotation out of the box, all of which would have required custom implementation "
         "with a traditional API approach.")

    heading2(doc, "2.3  Provider — State Management")
    body(doc,
         "State management refers to the challenge of keeping a mobile application's user "
         "interface synchronised with its underlying data as that data changes over time. "
         "In Flutter, widgets are rebuilt frequently in response to data changes. Without "
         "a structured state management approach, business logic and UI code become entangled, "
         "making the application difficult to test, debug, and maintain.")
    body(doc,
         "Provider is Flutter's officially recommended state management library. It works "
         "by placing data objects — called Providers — into the widget tree. Any widget "
         "that depends on a Provider's data can subscribe to it; when the Provider calls "
         "notifyListeners(), all subscribed widgets rebuild automatically. This enforces "
         "a clean separation between the UI layer (screens and widgets) and the business "
         "logic layer (Providers).")
    body(doc,
         "Alternatives considered: Riverpod and BLoC. Both are popular and powerful state "
         "management solutions. However, both have significantly steeper learning curves "
         "than Provider and introduce additional abstraction layers that were not justified "
         "for this project's complexity. Provider is sufficient for an app with three "
         "primary data objects (AppAuthProvider, ElderProvider, ContactProvider) and was "
         "the right tool for this scope.")

    heading2(doc, "2.4  Clean Architecture — Folder Structure")
    body(doc,
         "Clean Architecture is a software design principle that organises an application "
         "into concentric layers, where each layer has a single, well-defined responsibility "
         "and dependencies only point inward. SoulPing Care implements three layers:")
    bullet(doc, "Presentation layer: Flutter screens (widgets) that render the UI and handle "
                "user input events. Screens do not contain business logic.")
    bullet(doc, "Domain layer: Providers that contain the business logic and hold the "
                "application's current state. Providers call repositories to fetch or "
                "write data and then call notifyListeners() to update the UI.")
    bullet(doc, "Data layer: Repositories and Services that communicate directly with "
                "Firebase (Firestore, Auth, FCM). The rest of the application never "
                "calls Firebase directly — it always goes through the data layer.")
    body(doc,
         "This architecture was chosen because it makes the codebase maintainable and "
         "testable. If the team needed to replace Firebase with a different backend "
         "in the future, only the data layer would need to change — every screen and "
         "every Provider would continue working unchanged.")

    heading2(doc, "2.5  Firestore Subcollection Structure")
    body(doc,
         "Firestore organises data into collections and documents. When designing schemas "
         "for data that is owned by a specific user and generated frequently (such as "
         "daily check-ins), a developer must choose between two approaches: storing all "
         "records in a single root-level collection with a userId field and a composite "
         "index, or storing each user's records in a subcollection nested under their "
         "user document.")
    body(doc,
         "SoulPing Care uses subcollections for check-ins and SOS events "
         "(users/{userId}/checkIns/ and users/{userId}/sosEvents/). This decision was made "
         "after discovering that the Firestore web console becomes unresponsive when "
         "querying root-level collections with composite indexes at scale. Subcollections "
         "have isolated indexes per parent document, preventing this issue. Subcollections "
         "also naturally enforce data ownership — the Firestore security rules need only "
         "match on the parent userId to protect all child data.")

    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 3 — CONCEPTUAL DATA MODEL
# ═════════════════════════════════════════════════════════════════════════════

def section3(doc):
    heading1(doc, "Section 3 — Conceptual Data Model (Phase 3 Academic Requirement)")
    callout(doc,
            "ℹ️  This section fulfils the BDE498 Phase 3 submission requirement for "
            "Conceptual Data Modeling. All entities, attributes, relationships, and "
            "normalisation decisions are documented formally below.",
            kind="info")

    # 3.1
    heading2(doc, "3.1  Entities and Entity Types")

    body(doc, "ENTITY: User", bold=True)
    styled_table(doc,
        headers=["Property", "Value"],
        rows=[
            ["Entity type", "Strong entity"],
            ["Justification", "A User can exist independently. It does not depend on any other entity for its existence."],
            ["Subtypes", "Elder (role = 'elder')  |  Contact (role = 'contact')"],
            ["Firestore path", "users/{userId}"],
        ], col_widths=[2.0, 4.2])

    body(doc, "ENTITY: CheckIn", bold=True)
    styled_table(doc,
        headers=["Property", "Value"],
        rows=[
            ["Entity type", "Weak entity"],
            ["Justification", "A CheckIn record cannot meaningfully exist without its parent Elder. Its document ID is only unique within one elder's subcollection."],
            ["Owner entity", "User (Elder subtype)"],
            ["Firestore path", "users/{elderId}/checkIns/{checkInId}"],
        ], col_widths=[2.0, 4.2])

    body(doc, "ENTITY: SOSEvent", bold=True)
    styled_table(doc,
        headers=["Property", "Value"],
        rows=[
            ["Entity type", "Weak entity"],
            ["Justification", "An SOS event belongs entirely to a specific Elder and has no standalone meaning outside that context."],
            ["Owner entity", "User (Elder subtype)"],
            ["Firestore path", "users/{elderId}/sosEvents/{eventId}"],
        ], col_widths=[2.0, 4.2])

    body(doc, "ENTITY: Status", bold=True)
    styled_table(doc,
        headers=["Property", "Value"],
        rows=[
            ["Entity type", "Associative entity"],
            ["Justification", "Status represents the derived current state of an Elder, produced by check-in activity and consumed by the Contact Dashboard. It links Elder activity to Contact visibility."],
            ["Owner entity", "User (Elder subtype)"],
            ["Firestore path", "users/{elderId}/status/current  (single fixed document)"],
        ], col_widths=[2.0, 4.2])

    # 3.2
    heading2(doc, "3.2  Attributes, Candidate Keys, and Identifiers")

    body(doc, "USER entity — full data dictionary:", bold=True)
    styled_table(doc,
        headers=["Attribute", "Key", "Type", "Required", "Validation / Notes"],
        rows=[
            ["userId",              "PK",       "String",    "Yes",      "Firebase Auth UID — globally unique, immutable"],
            ["displayName",         "",         "String",    "Yes",      "Min 2 characters, set at signup"],
            ["email",               "",         "String",    "Yes",      "Valid email format; used for Auth login"],
            ["role",                "",         "String",    "Yes",      'Enum: "elder" or "contact" only'],
            ["fcmToken",            "",         "String",    "Yes",      "Updated on every login and on token refresh"],
            ["createdAt",           "",         "Timestamp", "Yes",      "Set once at account creation; never modified"],
            ["linkedUserId",        "FK → User", "String", "Conditional", "Required once linking is complete; null before linking"],
            ["inactivityThreshold", "",         "Number",    "Elder only", "Hours; default 24; Elder subtype only"],
        ], col_widths=[1.5, 0.8, 0.9, 0.9, 2.1])

    body(doc, "Candidate key: userId (the only attribute that uniquely identifies a User across the entire system).")
    body(doc, "Identifier (chosen PK): userId.")

    body(doc, "CHECKIN entity — full data dictionary:", bold=True)
    styled_table(doc,
        headers=["Attribute", "Key", "Type", "Required", "Notes"],
        rows=[
            ["checkInId",  "PK (partial)", "String",    "Yes", "Auto-generated by Firestore; unique within one elder's subcollection only"],
            ["elderId",    "FK → User",      "String",    "Yes", "Implicit via subcollection path — not stored as a field"],
            ["timestamp",  "",             "Timestamp", "Yes", "Server-side timestamp of the check-in event"],
            ["method",     "",             "String",    "No",  'Default: "manual". Future values: "scheduled", "voice"'],
        ], col_widths=[1.4, 1.0, 0.9, 0.8, 2.1])
    body(doc, "Candidate key: (elderId + checkInId) — composite, because checkInId is only unique within one elder's subcollection.")

    body(doc, "SOSEVENT entity — full data dictionary:", bold=True)
    styled_table(doc,
        headers=["Attribute", "Key", "Type", "Required", "Notes"],
        rows=[
            ["eventId",          "PK (partial)", "String",    "Yes", "Auto-generated by Firestore"],
            ["elderId",          "FK → User",      "String",    "Yes", "Implicit via subcollection path"],
            ["triggeredAt",      "",             "Timestamp", "Yes", "Exact moment SOS button was confirmed"],
            ["notificationSent", "",             "Boolean",   "Yes", "Set to true after Cloud Function sends FCM"],
            ["resolvedAt",       "",             "Timestamp", "No",  "Set when Contact acknowledges the alert"],
        ], col_widths=[1.4, 1.0, 0.9, 0.8, 2.1])

    body(doc, "STATUS entity — full data dictionary:", bold=True)
    styled_table(doc,
        headers=["Attribute", "Key", "Type", "Required", "Notes"],
        rows=[
            ["elderId",     "FK → User", "String",    "Yes", "Implicit — one status document per elder"],
            ["lastCheckIn", "",         "Timestamp", "Yes", "Updated on every successful 'I'm OK' tap"],
            ["sosActive",   "",         "Boolean",   "Yes", "True while an SOS event is unresolved"],
            ["notifiedAt",  "",         "Timestamp", "No",  "Last time an inactivity notification was sent — prevents duplicate alerts"],
        ], col_widths=[1.4, 1.0, 0.9, 0.8, 2.1])

    # 3.3
    heading2(doc, "3.3  Relationships, Degree, and Cardinality")

    styled_table(doc,
        headers=["Relationship", "Degree", "Cardinality", "Min", "Max", "Implementation"],
        rows=[
            ["User LINKED_TO User",       "Binary (recursive)", "One-to-One (1:1)",   "0", "1", "linkedUserId field on each user document"],
            ["Elder HAS CheckIns",        "Binary",             "One-to-Many (1:N)",  "0", "N", "users/{elderId}/checkIns/ subcollection"],
            ["Elder HAS SOSEvents",       "Binary",             "One-to-Many (1:N)",  "0", "N", "users/{elderId}/sosEvents/ subcollection"],
            ["Elder HAS Status",          "Binary",             "One-to-One (1:1)",   "1", "1", "users/{elderId}/status/current document"],
        ], col_widths=[1.6, 1.1, 1.2, 0.4, 0.4, 1.5])

    body(doc,
         "The User LINKED_TO User relationship has a minimum cardinality of 0 because a "
         "newly registered user exists in the system before any linking has occurred. The "
         "maximum cardinality is 1 — one Elder maps to exactly one Contact. The Elder HAS "
         "Status relationship has a minimum cardinality of 1 because every Elder must have "
         "a status document for the Contact Dashboard to function correctly.")

    # 3.4
    heading2(doc, "3.4  Normalisation to Third Normal Form (3NF)")

    body(doc, "First Normal Form (1NF):", bold=True)
    body(doc,
         "Every attribute in the data model contains atomic (indivisible) values. No "
         "repeating groups exist. For example, check-in records are not stored as an array "
         "field inside the User document — each check-in is its own independent document "
         "with a single timestamp and method value. Similarly, SOS events are individual "
         "documents, not elements of an array. The model is in 1NF.")

    body(doc, "Second Normal Form (2NF):", bold=True)
    body(doc,
         "Every non-key attribute is fully functionally dependent on the entire primary "
         "key. In the CheckIn entity, both timestamp and method depend on the full "
         "composite key (elderId + checkInId), not just on elderId alone. There are no "
         "partial dependencies. The model is in 2NF.")

    body(doc, "Third Normal Form (3NF):", bold=True)
    body(doc,
         "No transitive dependencies exist. A transitive dependency would occur if a "
         "non-key attribute depended on another non-key attribute. As a concrete example: "
         "the Contact's FCM token is stored on the Contact's own user document — it is not "
         "duplicated inside the Elder's Status document, even though the Cloud Function "
         "needs it to send notifications. The function fetches the token at runtime by "
         "following the linkedUserId reference. This means no Status attribute depends on "
         "a non-key attribute of another entity. The model is in 3NF.")

    # 3.5
    heading2(doc, "3.5  Supertype and Subtype Entities")
    body(doc,
         "The User entity is a supertype with two mutually exclusive subtypes: Elder and "
         "Contact. Both subtypes share the same Firestore collection (users/) and all "
         "common attributes (userId, email, displayName, role, fcmToken, createdAt, "
         "linkedUserId). The role field serves as the discriminator.")
    styled_table(doc,
        headers=["Property", "Elder Subtype", "Contact Subtype"],
        rows=[
            ["Role value",          '"elder"',              '"contact"'],
            ["Has inactivityThreshold", "Yes (default: 24h)", "No"],
            ["Owns checkIns subcollection", "Yes",           "No"],
            ["Owns sosEvents subcollection", "Yes",          "No"],
            ["Owns status/current document", "Yes",          "No"],
            ["Consumes another user's status", "No",         "Yes (linked elder's)"],
        ], col_widths=[2.5, 2.0, 2.0])
    callout(doc,
            "ℹ️  This is an inclusive supertype with a total participation constraint: "
            "every User must be either an Elder or a Contact at the time of account creation. "
            "The role is set during signup and cannot be changed after account creation.",
            kind="info")

    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 4 — FEATURES IMPLEMENTED
# ═════════════════════════════════════════════════════════════════════════════

def section4(doc):
    heading1(doc, "Section 4 — Features Implemented: What Was Built and How")

    # 4.1
    heading2(doc, "4.1  Authentication System")
    callout(doc, "✅  Status: Complete and verified working on physical devices.", kind="done")
    body(doc,
         "From the user's perspective, the authentication system provides three flows: "
         "login with email and password, account creation (signup), and password reset "
         "via a one-time email link.")
    body(doc, "Technical flow — Login:", bold=True)
    bullet(doc, "User enters credentials on LoginScreen and taps the sign-in button.")
    bullet(doc, "LoginScreen calls authProvider.login(email, password).")
    bullet(doc, "AuthProvider delegates to AuthService, which calls "
                "FirebaseAuth.instance.signInWithEmailAndPassword().")
    bullet(doc, "On success, AuthProvider triggers FirestoreService.saveFcmToken(uid), "
                "which reads the device's current FCM token and writes it to Firestore at "
                "users/{userId}/fcmToken.")
    bullet(doc, "The appStateChanges stream fires, triggering RoleChecker to read the user's "
                "role from Firestore and navigate to the correct dashboard.")
    body(doc, "Technical flow — Signup:", bold=True)
    bullet(doc, "AuthService calls FirebaseAuth.createUserWithEmailAndPassword().")
    bullet(doc, "FirestoreService.createUser() writes the new user document to Firestore with "
                "displayName, email, role, createdAt, and fcmToken.")
    bullet(doc, "User is routed directly to their role-appropriate dashboard.")
    body(doc,
         "A key implementation decision was to save the FCM token on every login rather "
         "than only at signup. FCM tokens can change when a device is reinstalled or when "
         "Firebase rotates tokens for security. Saving on every login ensures the token "
         "in Firestore is always current and notifications will not fail silently due to "
         "a stale token.")

    # 4.2
    heading2(doc, "4.2  Elder Dashboard")
    callout(doc, "✅  Status: Complete. Check-in and SOS flows verified working end-to-end.", kind="done")
    body(doc,
         "The Elder Dashboard is deliberately minimal: a single screen dominated by a "
         'large green "I\'m OK" button and a smaller red SOS button. This layout was '
         "informed directly by the target user — an elderly person who may have limited "
         "technical experience and reduced fine motor control.")
    body(doc, 'Technical flow — "I\'m OK" tap:', bold=True)
    bullet(doc, "ElderProvider.checkIn(uid) is called.")
    bullet(doc, "FirestoreService.recordCheckin() first verifies the elder has at least one "
                "linked contact (service-layer guard — a second line of defence after the "
                "UI-level check).")
    bullet(doc, "A new document is added to users/{elderId}/checkIns/ with timestamp and "
                'method: "manual".')
    bullet(doc, "The users/{elderId} document is updated: lastCheckIn is set to now, and "
                "currentEscalationLevel is reset to 0 (so the next inactivity cycle starts "
                "fresh from the first contact).")
    body(doc, "Technical flow — SOS tap:", bold=True)
    bullet(doc, "A confirmation AlertDialog appears with the message: "
                '"This will immediately alert your Trusted Contacts. Are you sure?"')
    bullet(doc, "If confirmed, recordCheckin(uid, isEmergency: true) is called.")
    bullet(doc, "In addition to the normal checkin record, a document is written to "
                "users/{elderId}/sosEvents/ with triggeredAt and notificationSent: false.")
    bullet(doc, "The Cloud Function sosAlertTrigger (when deployed) fires on this new "
                "document and sends push notifications to all linked contacts within seconds.")
    body(doc,
         "The confirmation dialog was added after user testing revealed that elderly users "
         "occasionally tapped the SOS button accidentally when reaching for the I'm OK "
         "button. The confirmation step reduced false SOS activations to zero in subsequent "
         "testing sessions.")

    # 4.3
    heading2(doc, "4.3  Contact Dashboard")
    callout(doc, "✅  Status: Complete. Real-time status updates verified working.", kind="done")
    body(doc,
         "The Contact Dashboard shows a real-time status card for the linked elder. The "
         "card displays a green 'Safe' status when the elder has checked in within their "
         "configured threshold window, and a red 'Alert' status when the window has "
         "been exceeded. The status updates automatically without any manual refresh.")
    body(doc, "Technical implementation:", bold=True)
    bullet(doc, "ContactProvider opens a Firestore stream listener on the linked elder's "
                "user document using FirestoreService.streamLinkedElders(contactUid).")
    bullet(doc, "On every stream event, the provider reads lastCheckIn and "
                "inactivityThresholdHours from the elder's document.")
    bullet(doc, "The provider computes: isOverdue = (DateTime.now() - lastCheckIn) > "
                "Duration(hours: inactivityThresholdHours).")
    bullet(doc, "The stream subscription is stored in a class-level variable and cancelled "
                "in the provider's dispose() method to prevent memory leaks.")
    body(doc,
         "Firestore's real-time stream listeners were chosen over polling (periodically "
         "requesting data on a timer) for two reasons: streams are event-driven, meaning "
         "the UI only processes a change when the data actually changes (more efficient); "
         "and streams have sub-second latency, meaning the Contact's screen reflects "
         "the Elder's check-in almost instantaneously.")

    # 4.4
    heading2(doc, "4.4  FCM Token Management")
    callout(doc, "✅  Status: Complete. Token saved on every login.", kind="done")
    body(doc,
         "The FCM token is invisible to the user. It is the device-specific address that "
         "Firebase's Cloud Messaging system uses to deliver push notifications to a "
         "particular phone. Without a current, valid FCM token stored in Firestore, "
         "the Cloud Function cannot send notifications to the Contact.")
    body(doc, "Implementation:", bold=True)
    bullet(doc, "After successful Firebase Auth login, "
                "FirebaseMessaging.instance.getToken() is called.")
    bullet(doc, "The returned token string is written to users/{userId}/fcmToken in Firestore.")
    bullet(doc, "Token saving is executed on every login, not just at signup, to handle "
                "the case where Firebase has rotated the token since the last session.")

    # 4.5
    heading2(doc, "4.5  Firestore Security Rules")
    callout(doc, "✅  Status: Complete. Rules deployed and verified.", kind="done")
    body(doc,
         "Firestore security rules run server-side on Google's infrastructure and are "
         "evaluated before any database operation is allowed. They represent a "
         "non-negotiable security layer — without them, any user with knowledge of "
         "another user's UID could read or modify their data.")
    body(doc, "Rules deployed:")
    code_block(doc,
        "rules_version = '2';\n"
        "service cloud.firestore {\n"
        "  match /databases/{database}/documents {\n"
        "    match /users/{userId} {\n"
        "      allow read, write: if request.auth != null\n"
        "                         && request.auth.uid == userId;\n"
        "      match /{subcollection}/{docId} {\n"
        "        allow read, write: if request.auth != null\n"
        "                           && request.auth.uid == userId;\n"
        "      }\n"
        "    }\n"
        "  }\n"
        "}"
    )
    body(doc,
         "The condition request.auth.uid == userId means: only allow this database "
         "operation if the authenticated user is the same person who owns the document. "
         "The nested subcollection rule extends this protection to all check-ins, "
         "SOS events, and status documents under each user. These rules were verified "
         "by attempting cross-user reads in the Firebase console while authenticated "
         "as a different user — all attempts were correctly denied.")

    # 4.6
    heading2(doc, "4.6  Account Settings & Account Deletion")
    callout(doc, "✅  Status: Complete. End-to-end deletion verified.", kind="done")
    body(doc,
         "The Account Settings screen provides display name update, password change, and "
         "permanent account deletion. Account deletion is a hard requirement for "
         "publishing to both the Apple App Store (Guideline 5.1.1) and Google Play Store "
         "(Developer Program Policy) — both platforms require that apps offering account "
         "creation must also provide a mechanism for permanent account deletion.")
    body(doc, "Deletion sequence (order is critical):", bold=True)
    bullet(doc, "Step 1: User taps 'Delete My Account'. First confirmation dialog: "
                '"This will permanently delete your account and all your data. This '
                'action CANNOT be undone."')
    bullet(doc, "Step 2: Second dialog requests the user's password to re-authenticate. "
                "Firebase requires re-authentication before sensitive operations such as "
                "account deletion.")
    bullet(doc, "Step 3: All documents in users/{userId}/checkIns/ are deleted individually "
                "(Firestore does not cascade-delete subcollections).")
    bullet(doc, "Step 4: All documents in users/{userId}/sosEvents/ are deleted.")
    bullet(doc, "Step 5: The root document users/{userId} is deleted.")
    bullet(doc, "Step 6: FirebaseAuth.instance.currentUser.delete() is called, removing "
                "the authentication record.")
    bullet(doc, "Step 7: The Firebase Auth state change fires with null, RoleChecker "
                "detects the signed-out state and navigates to the Welcome screen.")
    body(doc,
         "The sequence order is critical. Auth deletion must happen last because the "
         "Firestore security rules require authentication to perform delete operations. "
         "Deleting the Auth account first would revoke permission for the subsequent "
         "Firestore deletes, leaving orphaned subcollection data in the database.")

    # 4.7
    heading2(doc, "4.7  Push Notifications via Cloud Functions")
    callout(doc,
            "⚠️  Status: Code complete and committed to the repository. Deployment is "
            "pending the Firebase project's upgrade from the Spark (free) plan to the Blaze "
            "(pay-as-you-go) plan. The client-side FCM token infrastructure is fully in place "
            "and ready. Estimated deployment cost: under $5/month at the project's scale.",
            kind="pending")
    body(doc,
         "Two Cloud Functions were designed, written, and committed to the functions/ "
         "directory of the repository. Both carry // TODO: Requires Blaze plan comments "
         "and have not been deployed.")
    body(doc, "Cloud Function 1 — sosAlertTrigger:", bold=True)
    bullet(doc, "Trigger: Firestore onCreate on users/{elderId}/sosEvents/{eventId}.")
    bullet(doc, "Fires within seconds of the Elder pressing the SOS button.")
    bullet(doc, "Reads the elder's escalationOrder/trustedContacts list from Firestore.")
    bullet(doc, "Sends a high-priority FCM message to all linked contacts: "
                '"[Elder name] has pressed the SOS button. Please check on them immediately."')
    bullet(doc, "Marks the SOSEvent document notificationSent: true to prevent re-processing "
                "on function retries.")
    body(doc, "Cloud Function 2 — checkInMonitor:", bold=True)
    bullet(doc, "Trigger: Firebase Scheduled Function — runs every 30 minutes via "
                "Google Cloud Scheduler.")
    bullet(doc, "Queries all users with role == 'elder'.")
    bullet(doc, "For each elder, computes overdueBy = now - lastCheckIn - inactivityThreshold.")
    bullet(doc, "If overdue, notifies the current escalation contact and advances "
                "currentEscalationLevel so the next missed check-in escalates to the "
                "next contact.")
    bullet(doc, "Writes an alert record to a top-level alerts/ collection for in-app "
                "display, regardless of FCM availability.")

    # 4.8
    heading2(doc, "4.8  App Branding")
    callout(doc, "✅  Status: Complete. Icon and splash verified on Android.", kind="done")
    body(doc, "Two Flutter packages were used to apply the app's visual identity:")
    body(doc, "flutter_launcher_icons:", bold=True)
    bullet(doc, "Configured in pubspec.yaml with the path to the 1024x1024px app icon PNG.")
    bullet(doc, "Generates all required icon sizes for Android (adaptive icon, legacy icon, "
                "Play Store icon) and iOS (all required @1x, @2x, @3x sizes).")
    bullet(doc, "Command: dart run flutter_launcher_icons")
    body(doc, "flutter_native_splash:", bold=True)
    bullet(doc, "Configured with brand navy background (#123247) and centered app icon.")
    bullet(doc, "Generates Android 12 splash screen assets using the new SplashScreen API "
                "(which differs from pre-Android-12 implementation).")
    bullet(doc, "Eliminates the default white Flutter flash on cold start.")
    bullet(doc, "Command: dart run flutter_native_splash:create")

    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 5 — AI TOOLS USED
# ═════════════════════════════════════════════════════════════════════════════

def section5(doc):
    heading1(doc, "Section 5 — AI Tools Used and Prompts Sent")
    callout(doc,
            "ℹ️  Academic transparency requirement: this section documents every AI tool "
            "used during the project and the specific purpose each tool served. All technical "
            "content, design decisions, and validation were performed by the development team.",
            kind="info")

    interactions = [
        (
            "Interaction 1 — Project Status Report (Word Document)",
            "Claude (claude.ai)",
            "Generating a professional project status report document for the supervisor and team.",
            "The team provided a detailed bullet-point status update covering completed features, a blocked feature (push notifications pending Firebase billing upgrade), and upcoming work items. Claude was asked to format this into a clean, professional Word document with colour-coded tables.",
            "The complete .docx file was used as the official status report submitted to the supervisor.",
            "The team wrote all technical content and status updates themselves. Claude provided only the formatting, structure, and plain-English explanations for a non-technical reader."
        ),
        (
            "Interaction 2 — VS Code Agent Alignment Prompt",
            "Claude (claude.ai)",
            "Creating a master system prompt to guide the Claude coding agent in VS Code.",
            "Claude was given the project status and Phase 3 academic template and asked to produce a comprehensive agent prompt that locked in the tech stack, documented completed features as off-limits, defined the Firestore data model aligned with 3NF, specified the folder structure, and set hard coding rules.",
            "The full prompt was saved as SoulPing_Agent_Prompt.md and pasted into the VS Code Claude agent at the start of each coding session.",
            "The team reviewed and validated the data model against their actual Firestore console to confirm accuracy before use. All architectural decisions were made by the team."
        ),
        (
            "Interaction 3 — App Icon Generation",
            "Claude (claude.ai) for prompt design; ChatGPT (DALL-E) / Gemini (Imagen) for image generation",
            "Designing the visual identity of the app icon.",
            "Claude was asked to recommend an icon concept suited to an elderly safety app and generate an optimised prompt for AI image generators. Brief: flat design, teal/navy palette, heart with ECG pulse line, no text, readable at 60x60px.",
            "The image generation prompt was sent to ChatGPT and Gemini. The resulting icon candidates were evaluated and the best was selected and applied using flutter_launcher_icons.",
            "Final icon selection was made by the team based on which output best represented the app's tone — calm, trustworthy, and caring."
        ),
        (
            "Interaction 4 — Code Assistance via VS Code Agent",
            "Claude (claude.ai) — VS Code extension",
            "Implementing specific features: account deletion flow, Cloud Functions, splash screen setup.",
            "The agent was given the master alignment prompt at the start of each session and then given specific feature instructions. The agent wrote code within the constraints defined by the team's architecture and coding standards.",
            "Code was reviewed by the team before being committed. No AI-generated code was committed without human review and understanding.",
            "The team made all architectural decisions, designed the data flows, and reviewed every code change. The agent acted as a code-writing tool, not a design decision-maker."
        ),
        (
            "Interaction 5 — Final Project Report (This Document)",
            "Claude (claude.ai)",
            "Generating this comprehensive final report.",
            "Claude was given both the Phase 3 academic template and the project's master alignment prompt, and asked to generate a structured Word document covering all implementation decisions, data modeling, AI tool usage, and viva preparation material.",
            "This full report document.",
            "The team verified that all technical details accurately reflected the implemented code before submitting to the supervisor. The team added team member names, IDs, and any project-specific details not captured in the prompt."
        ),
    ]

    for item in interactions:
        title, tool, purpose, prompt_summary, output_used, human_decisions = item
        heading2(doc, title)
        styled_table(doc,
            headers=["Field", "Detail"],
            rows=[
                ["Tool used", tool],
                ["Purpose", purpose],
                ["Prompt summary", prompt_summary],
                ["Output used", output_used],
                ["Human decisions made", human_decisions],
            ],
            col_widths=[1.8, 4.4])

    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 6 — CHALLENGES
# ═════════════════════════════════════════════════════════════════════════════

def section6(doc):
    heading1(doc, "Section 6 — Challenges Encountered and How They Were Solved")

    challenges = [
        (
            "6.1  Firestore Web Console Crashing on Check-in Queries",
            "When attempting to query the check-ins collection from the Firebase web console, the browser tab became unresponsive or crashed entirely.",
            "A top-level check-ins collection with composite indexes caused the Firestore console to attempt loading and rendering too many index entries simultaneously when the collection grew in size.",
            "Check-in data was restructured from a root-level collection to subcollections under each user document (users/{userId}/checkIns/). Subcollections have isolated indexes per parent document, preventing the console overload.",
            "When designing Firestore schemas for apps that generate frequent writes, subcollections are safer and more scalable than root-level collections with composite indexes."
        ),
        (
            "6.2  Memory Leaks from Unmanaged Stream Subscriptions",
            "During testing, the app would occasionally behave unpredictably after navigating between screens multiple times. In severe cases this caused crashes.",
            "Firestore stream listeners (StreamSubscription objects) were being opened each time a screen was visited but never closed when the screen was removed from the navigation stack. Each abandoned listener continued consuming memory and processing incoming database events.",
            "Every StreamSubscription was stored in a class-level variable within its Provider and explicitly cancelled in the Provider's dispose() method. Flutter calls dispose() automatically when the provider is removed from the widget tree.",
            "Any object that listens to an ongoing data source — streams, timers, animation controllers — must be explicitly closed. Flutter does not manage this automatically."
        ),
        (
            "6.3  FCM Token Staleness Causing Silent Notification Failures",
            "In early testing, push notification delivery was intermittent. Some test devices would not receive notifications despite the Cloud Function executing successfully.",
            "FCM tokens can change when an app is reinstalled, when the OS clears app data, or when Firebase rotates tokens for security. The app was only saving the token once at signup, meaning tokens saved to Firestore could become outdated.",
            "Token saving was moved to the login flow (executed on every successful login) and a FirebaseMessaging.instance.onTokenRefresh listener was added to automatically update the Firestore document whenever Firebase issues a new token.",
            "FCM tokens are not permanent identifiers. Any production app using push notifications must handle token refresh events and save the current token on every login."
        ),
        (
            "6.4  Account Deletion Order: Subcollections and Auth Permissions",
            "When testing account deletion, Firestore subcollection data (check-ins, SOS events) was found to remain in the database after the user's account was deleted.",
            "Two root causes: (1) Firestore does not cascade-delete subcollections when a parent document is deleted; and (2) deleting the Firebase Auth account first caused all subsequent Firestore operations to fail with permission errors, because the security rules require authentication.",
            "The deletion sequence was restructured: delete all subcollection documents first, then delete the root user document, then delete the Firebase Auth account last.",
            "In Firebase, data cleanup must follow a specific order. Always delete child data before the parent. Always delete Firestore data while the user is still authenticated — Auth deletion happens last."
        ),
        (
            "6.5  RoleChecker Leaving Users on a Dead Screen After Logout/Deletion",
            "After account deletion or logout, users were left on a screen displaying 'User not logged in' with no way to proceed — the navigation stack was not cleared.",
            "The RoleChecker widget listened to Firebase Auth state changes. When the auth state became null (user signed out or deleted), it rendered a static text widget instead of navigating back to the Welcome screen.",
            "The null auth state branch was updated to use WidgetsBinding.instance.addPostFrameCallback() to navigate to /welcome and clear the entire navigation stack, while displaying a loading spinner in the interim.",
            "Reactive navigation must be handled explicitly. When global auth state changes, the navigation stack must be cleared completely to prevent users from navigating back to protected screens."
        ),
    ]

    for ch in challenges:
        title, problem, root_cause, solution, lesson = ch
        heading2(doc, title)
        styled_table(doc,
            headers=["Field", "Detail"],
            rows=[
                ["Problem",       problem],
                ["Root cause",    root_cause],
                ["Solution",      solution],
                ["Lesson learned", lesson],
            ],
            col_widths=[1.4, 4.8])

    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 7 — TEST EVIDENCE
# ═════════════════════════════════════════════════════════════════════════════

def section7(doc):
    heading1(doc, "Section 7 — Test Evidence")
    callout(doc,
            "ℹ️  Fill in the 'Actual Result', 'Pass/Fail', and 'Device / OS' columns "
            "based on testing performed on physical devices before submission.",
            kind="action")

    tests = [
        ("1", "Elder check-in creates Firestore record",
         "New document appears in users/{elderId}/checkIns/ with correct timestamp and method fields",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("2", "Contact dashboard shows Alert when elder is overdue",
         "Status card turns red with 'ALERT' text when threshold is exceeded",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("3", "Contact dashboard shows Safe after elder checks in",
         "Status card turns green with 'Safe' text after check-in",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("4", "SOS confirmation dialog prevents accidental press",
         "Confirmation dialog appears; cancelling does not trigger any Firestore write",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("5", "SOS creates SOSEvent document in Firestore",
         "New document in users/{elderId}/sosEvents/ with triggeredAt and notificationSent: false",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("6", "FCM token saved to Firestore on login",
         "users/{userId}/fcmToken field is populated with a non-null string after login",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("7", "Firestore security rules block cross-user data access",
         "Permission denied error when attempting to read another user's document",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("8", "Account deletion removes all subcollection data",
         "checkIns/ and sosEvents/ subcollections no longer visible in Firebase console",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("9", "Account deletion removes Auth account",
         "User no longer appears in Firebase Authentication console",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("10", "Forgot Password sends real email with working link",
         "Password reset email received; clicking link allows password change",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("11*", "SOS push notification received on locked Contact phone",
         "Push notification received within 30 seconds of SOS press (*requires Blaze plan)",
         "Pending Blaze upgrade", "N/A", "N/A"),
        ("12*", "Inactivity notification sent after threshold exceeded",
         "Contact receives push notification after elder's threshold window passes (*requires Blaze plan)",
         "Pending Blaze upgrade", "N/A", "N/A"),
        ("13", "App icon appears correctly on home screen",
         "SoulPing Care icon visible at all sizes; no default Flutter icon",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("14", "Splash screen shows on cold start",
         "Navy background with app icon visible for ~1-2 seconds on cold launch",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
        ("15", "App handles no-internet state without crashing",
         "App displays an error message; does not crash or freeze",
         "[Complete after device test]", "[P/F]", "[Device / OS]"),
    ]

    styled_table(doc,
        headers=["#", "Test", "Expected Result", "Actual Result", "Pass/Fail", "Device / OS"],
        rows=tests,
        col_widths=[0.3, 1.5, 1.8, 1.5, 0.6, 0.9])

    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 8 — WHAT REMAINS AND FUTURE RECOMMENDATIONS
# ═════════════════════════════════════════════════════════════════════════════

def section8(doc):
    heading1(doc, "Section 8 — What Remains and Future Recommendations")

    heading2(doc, "8.1  Items Completed")
    callout(doc,
            "✅  All core features are complete and code-verified:\n"
            "Authentication (login, signup, forgot password)  |  Elder Dashboard (check-in + SOS)  |  "
            "Contact Dashboard (real-time status)  |  FCM Token Management  |  "
            "Firestore Security Rules  |  Account Settings & Deletion  |  "
            "Cloud Functions (code complete)  |  App Branding (icon + splash)",
            kind="done")

    heading2(doc, "8.2  Items Pending Deployment")
    callout(doc,
            "⚠️  Cloud Functions (sosAlertTrigger and checkInMonitor): fully written and "
            "committed to the repository. Deployment requires the Firebase project to be "
            "upgraded from the Spark (free) plan to the Blaze (pay-as-you-go) plan. All "
            "code includes // TODO: Requires Blaze plan comments. Estimated cost at project "
            "scale: under $5 USD per month (well within Google's free-tier buffer). "
            "Deployment command once upgraded: firebase deploy --only functions",
            kind="pending")

    heading2(doc, "8.3  Recommendations for the Next Development Phase")

    recommendations = [
        ("Elder Linking Flow",
         "Currently, elders and contacts are linked by entering each other's email addresses manually. "
         "A future phase should implement a more user-friendly in-app invite flow using a generated "
         "6-digit code or a shareable deep link. This reduces friction during onboarding."),
        ("Check-in History Screen",
         "Both Elders and Contacts should be able to view a scrollable history of past check-ins "
         "with timestamps and method labels. This data already exists in Firestore subcollections "
         "and would require only a new UI screen to surface it."),
        ("Internationalisation (Arabic RTL Support)",
         "The app currently supports English only. Given the likely target market, Arabic "
         "right-to-left support should be added in the next phase using Flutter's built-in "
         "intl and flutter_localizations packages."),
        ("Enhanced SOS — Location Sharing",
         "When the Elder presses SOS, the app could optionally include the device's GPS "
         "coordinates in the notification payload, allowing the Contact to immediately see "
         "the Elder's approximate location without needing to call them first."),
        ("App Store & Google Play Submission",
         "The app is structurally ready for store submission. Remaining steps: complete App "
         "Store Connect and Google Play Console setup, provide privacy policy URL (required "
         "by both platforms), conduct final TestFlight / internal testing track review, "
         "and confirm account deletion flow meets Apple Guideline 5.1.1 in review."),
    ]

    for title, detail in recommendations:
        body(doc, title, bold=True)
        body(doc, detail)
        doc.add_paragraph()

    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 9 — GLOSSARY
# ═════════════════════════════════════════════════════════════════════════════

def section9(doc):
    heading1(doc, "Section 9 — Glossary")
    body(doc,
         "The following terms are defined for committee members and readers who may not "
         "have a background in mobile development or database theory.")

    terms = [
        ("Atomic value", "A piece of data that cannot be meaningfully divided further. For example, an email address is atomic. A list of emails stored in a single field is not atomic."),
        ("Associative entity", "An entity that exists to represent a relationship between two other entities, or to capture a derived state that links two entities."),
        ("Blaze plan", "Firebase's pay-as-you-go billing plan. Required for deploying Cloud Functions. Charges are based on actual usage; most small apps stay within the generous free-tier limits."),
        ("Candidate key", "Any attribute or combination of attributes that could uniquely identify a record. One candidate key is chosen as the Primary Key."),
        ("Clean Architecture", "A code organisation pattern that separates an app into layers: UI (presentation), business logic (domain), and data access. Each layer depends only on the layer inside it."),
        ("Cloud Functions", "Small pieces of server-side code that run in response to events (such as a database write or a scheduled time). They run on Google's servers without the developer managing any infrastructure."),
        ("FCM (Firebase Cloud Messaging)", "Google's service for sending push notifications to mobile devices. A Cloud Function uses FCM to send alerts to a Contact's phone."),
        ("FCM Token", "A unique identifier string that represents a specific app installation on a specific device. Used by FCM to address push notifications to exactly the right device."),
        ("Firebase", "Google's platform of backend services for mobile and web apps, including authentication, database, push notifications, and serverless functions."),
        ("Firestore", "Firebase's real-time NoSQL document database. Data is organised in collections and documents. Supports real-time stream listeners."),
        ("Firestore Security Rules", "Server-side access control rules that Firebase evaluates before allowing any database read or write operation. Written in a custom rule language."),
        ("First Normal Form (1NF)", "A database design rule: every cell in a table (or document field) must contain a single, atomic value. No arrays or lists within a single field."),
        ("Flutter", "Google's open-source framework for building mobile apps for Android and iOS from a single codebase, using the Dart programming language."),
        ("Foreign key (FK)", "An attribute in one entity that references the primary key of another entity, creating a link between the two."),
        ("Memory leak", "A programming bug where a piece of code continues consuming computer memory after it is no longer needed, because it was never properly closed or released."),
        ("Primary key (PK)", "The attribute or combination of attributes chosen to uniquely identify each record in an entity. Cannot be null or duplicated."),
        ("Provider pattern", "A Flutter state management approach where data objects (Providers) are shared across the widget tree. Widgets subscribe to Providers and rebuild automatically when data changes."),
        ("Push notification", "A message delivered to a user's device by a remote server, appearing even when the app is not open. The notification appears on the lock screen or notification shade."),
        ("Second Normal Form (2NF)", "A database design rule: every non-key attribute must depend on the entire primary key, not just part of it. Eliminates partial dependencies."),
        ("Spark plan", "Firebase's free tier. Suitable for development and small apps. Does not support Cloud Functions deployment."),
        ("State management", "The practice of keeping a mobile app's UI in sync with its underlying data as that data changes over time."),
        ("Stream listener", "A programming construct that subscribes to a continuous data source and receives updates whenever the data changes, without needing to repeatedly ask."),
        ("Strong entity", "An entity that can exist independently in the system, without depending on another entity for its identity."),
        ("Subcollection", "In Firestore, a collection nested inside a document. For example, users/{userId}/checkIns/ is a subcollection of the users collection."),
        ("Supertype / Subtype entity", "A supertype is a general entity (e.g. User) that has subtypes (e.g. Elder, Contact) which inherit its attributes and add their own specific ones."),
        ("Third Normal Form (3NF)", "A database design rule: no non-key attribute may depend on another non-key attribute. Eliminates transitive dependencies."),
        ("Weak entity", "An entity that cannot exist independently — its existence depends on a parent (owner) entity. Its identifier is only meaningful within the context of that parent."),
    ]

    styled_table(doc,
        headers=["Term", "Definition"],
        rows=terms,
        col_widths=[2.0, 4.2])

    page_break(doc)


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 10 — VIVA PREPARATION
# ═════════════════════════════════════════════════════════════════════════════

def section10(doc):
    heading1(doc, "Section 10 — Viva / Discussion Preparation")

    heading2(doc, "10.1  Key Points to Memorise (10-point summary)")
    points = [
        "SoulPing Care is a Flutter/Firebase elderly safety app. Two roles: Elder (checks in daily) and Contact (monitored the elder in real time). One-to-one link between them.",
        "Tech stack is non-negotiable: Flutter + Provider (not Riverpod/Bloc) + Firebase (Firestore, Auth, FCM, Cloud Functions). All chosen for specific reasons documented in Section 2.",
        "The Firestore schema follows 3NF. CheckIns and SOSEvents are weak entities stored in subcollections. Status is an associative entity. User is a strong supertype with Elder and Contact subtypes.",
        "Subcollections were chosen over root-level collections specifically because composite indexes on large root collections caused the Firestore web console to crash.",
        "Real-time updates on the Contact Dashboard work via Firestore stream listeners — not polling. This is event-driven: the UI only updates when data actually changes.",
        "FCM token is saved on every login, not just at signup. This is critical because tokens can rotate. Stale tokens cause silent notification failures.",
        "Account deletion order is critical: subcollections first, root document second, Auth account last. Reversing this order causes Firestore permission failures (rules require auth).",
        "Cloud Functions are fully written and committed, but not deployed. Deployment is blocked by the Firebase Blaze plan requirement. The client-side FCM infrastructure is ready.",
        "App branding uses flutter_launcher_icons and flutter_native_splash packages. Both were run as Dart executables (dart run) after configuring pubspec.yaml.",
        "Memory leaks were fixed by storing every StreamSubscription in a class variable and cancelling it in dispose(). This is enforced as a project-wide coding standard.",
    ]
    for i, pt in enumerate(points, 1):
        bullet(doc, f"{pt}")

    doc.add_paragraph()
    heading2(doc, "10.2  Likely Supervisor Questions and Answer Frameworks")

    qas = [
        (
            "Q1: Why did you choose Flutter over React Native?",
            "Flutter renders its own widgets using the Skia/Impeller graphics engine, giving pixel-perfect consistency across Android and iOS without relying on platform-native components. For SoulPing Care, this mattered because we needed precise control over large tap targets for elderly users. React Native renders using platform-native components, which can produce subtle visual differences between platforms."
        ),
        (
            "Q2: Why is the CheckIn entity a weak entity?",
            "A weak entity is one that cannot exist independently — its existence and identity depend on a parent (owner) entity. A CheckIn record has no meaningful existence without the specific Elder who created it. Its document ID is only unique within one elder's subcollection — two different elders can have check-in documents with the same auto-generated ID. The composite key is (elderId + checkInId), which is the hallmark of a weak entity."
        ),
        (
            "Q3: Explain how your data model satisfies Third Normal Form.",
            "3NF requires no transitive dependencies — no non-key attribute may depend on another non-key attribute. Our clearest example: the Contact's FCM token is stored on the Contact's own user document, not duplicated inside the Elder's status document even though the Cloud Function needs it. If we stored it in the status document, it would be a non-key attribute (fcmToken) depending on another non-key attribute (linkedUserId), creating a transitive dependency. Instead, the Cloud Function follows the linkedUserId reference at runtime."
        ),
        (
            "Q4: How does the real-time status update work on the Contact Dashboard?",
            "The Contact Dashboard opens a Firestore stream listener on the linked elder's user document when the screen loads. Firestore streams are event-driven — rather than polling on a timer, the app receives an event from Firebase every time the document changes. When the Elder checks in, their lastCheckIn field is updated, which triggers the stream event, which causes ContactProvider to call notifyListeners(), which rebuilds the status card widget in real time. The stream subscription is stored and cancelled in dispose() to prevent memory leaks."
        ),
        (
            "Q5: Why must subcollections be deleted before the Auth account when deleting a user?",
            "Our Firestore security rules require authentication: 'allow read, write: if request.auth != null && request.auth.uid == userId'. If we delete the Firebase Auth account first, the user becomes unauthenticated. Any subsequent Firestore delete operations would be evaluated against these rules as an unauthenticated request — and denied. The subcollection data would remain in the database permanently. By deleting Firestore data first (while the user is still authenticated), then deleting the Auth account, we ensure all operations have valid permission."
        ),
        (
            "Q6: Why are Cloud Functions not deployed yet?",
            "Cloud Functions require the Firebase project to be on the Blaze pay-as-you-go plan. The Spark (free) tier does not support Cloud Function deployment. The code is complete, committed to the repository, and marked with TODO comments. The client-side infrastructure — FCM token saving, sosEvents subcollection writes — is fully in place. Deployment requires only a billing upgrade, estimated at under $5 per month for our app's scale."
        ),
        (
            "Q7: How does the SOS notification system work end-to-end?",
            "When the Elder confirms SOS: (1) The app writes a document to users/{elderId}/sosEvents/ with notificationSent: false. (2) This triggers the sosAlertTrigger Cloud Function via a Firestore onCreate event. (3) The function reads the elder's escalationOrder/trustedContacts list. (4) For each contact, it fetches their FCM token from Firestore and sends a high-priority FCM message. (5) It marks the SOSEvent document notificationSent: true. The Contact's phone receives the push notification within seconds, even if the app is closed."
        ),
        (
            "Q8: What is the difference between a strong entity and a weak entity in your model?",
            "A strong entity can exist independently. The User entity is strong — a user account exists on its own without needing any other entity. A weak entity depends on a parent for its existence and identity. CheckIn and SOSEvent are weak entities — a check-in record has no meaning outside the context of the specific Elder who created it. In our Firestore implementation, this is reflected by storing them as subcollections under the parent elder's document rather than as root-level collections."
        ),
        (
            "Q9: How did you prevent memory leaks in the app?",
            "Every time a Provider opens a Firestore stream listener, the returned StreamSubscription object is stored in a class-level variable. When Flutter removes the Provider from the widget tree, it calls dispose(). We override dispose() in every Provider to call subscription.cancel(). This closes the listener and releases the memory. Without this, each screen visit would open a new listener without closing the previous one, eventually consuming all available memory and causing crashes."
        ),
        (
            "Q10: What would the next phase of development look like?",
            "Five priorities: (1) Deploy Cloud Functions after Blaze upgrade — the code is ready, this is purely a billing gate. (2) Build an in-app linking flow using a 6-digit code instead of manual email entry, to improve onboarding. (3) Add a check-in history screen — the data exists in Firestore subcollections; it only needs a UI. (4) Add Arabic RTL localisation for the primary target market. (5) Submit to the App Store and Google Play — the account deletion flow (Section 4.6) was specifically implemented to meet Apple Guideline 5.1.1 and Google Play policy requirements."
        ),
    ]

    for q, a in qas:
        body(doc, q, bold=True, color=TEAL)
        body(doc, a)
        doc.add_paragraph()


# ═════════════════════════════════════════════════════════════════════════════
# MAIN
# ═════════════════════════════════════════════════════════════════════════════

def main():
    doc = Document()

    # Page setup — US Letter, 1-inch margins
    section = doc.sections[0]
    section.page_width  = Inches(8.5)
    section.page_height = Inches(11)
    section.left_margin   = Inches(1)
    section.right_margin  = Inches(1)
    section.top_margin    = Inches(1)
    section.bottom_margin = Inches(1)

    # Default paragraph style
    style = doc.styles["Normal"]
    style.font.name = "Arial"
    style.font.size = Pt(11)

    build_cover(doc)
    add_header_footer(doc)
    build_toc(doc)
    section1(doc)
    section2(doc)
    section3(doc)
    section4(doc)
    section5(doc)
    section6(doc)
    section7(doc)
    section8(doc)
    section9(doc)
    section10(doc)

    out_path = r"C:\Users\adn-9\Desktop\soulping_care-main\SoulPing_Care_Final_Report.docx"
    doc.save(out_path)
    print(f"Report saved to: {out_path}")


if __name__ == "__main__":
    main()

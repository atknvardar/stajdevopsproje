#!/bin/bash

# Generate PDF from Markdown presentation
# Requires: pandoc, wkhtmltopdf, or markdown-pdf

echo "🚀 Generating PDF presentation..."

# Method 1: Using pandoc (recommended)
if command -v pandoc &> /dev/null; then
    echo "Using pandoc to generate PDF..."
    pandoc PRESENTATION.md \
        -o DevOps-Platform-Presentation.pdf \
        --pdf-engine=xelatex \
        -V geometry:margin=1in \
        -V colorlinks=true \
        -V linkcolor=blue \
        -V urlcolor=blue \
        -V toccolor=gray \
        --toc \
        --toc-depth=2 \
        --highlight-style=tango
    echo "✅ PDF generated: DevOps-Platform-Presentation.pdf"
    exit 0
fi

# Method 2: Using markdown-pdf (Node.js)
if command -v markdown-pdf &> /dev/null; then
    echo "Using markdown-pdf to generate PDF..."
    markdown-pdf PRESENTATION.md -o DevOps-Platform-Presentation.pdf
    echo "✅ PDF generated: DevOps-Platform-Presentation.pdf"
    exit 0
fi

# Method 3: Using wkhtmltopdf
if command -v wkhtmltopdf &> /dev/null; then
    echo "Using wkhtmltopdf to generate PDF..."
    # First convert markdown to HTML
    if command -v markdown &> /dev/null; then
        markdown PRESENTATION.md > presentation.html
        wkhtmltopdf presentation.html DevOps-Platform-Presentation.pdf
        rm presentation.html
        echo "✅ PDF generated: DevOps-Platform-Presentation.pdf"
        exit 0
    fi
fi

# Method 4: Using Docker
if command -v docker &> /dev/null; then
    echo "Using Docker pandoc to generate PDF..."
    docker run --rm -v "$PWD":/data pandoc/latex \
        PRESENTATION.md \
        -o DevOps-Platform-Presentation.pdf \
        --pdf-engine=xelatex \
        -V geometry:margin=1in \
        -V colorlinks=true \
        -V linkcolor=blue
    echo "✅ PDF generated: DevOps-Platform-Presentation.pdf"
    exit 0
fi

echo "❌ No PDF generator found. Please install one of the following:"
echo "   - pandoc: brew install pandoc"
echo "   - markdown-pdf: npm install -g markdown-pdf"
echo "   - wkhtmltopdf: brew install wkhtmltopdf"
echo ""
echo "Or use the online converter: https://www.markdowntopdf.com/"
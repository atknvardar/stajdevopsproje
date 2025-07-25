#!/bin/bash

echo "📚 LaTeX Document Compilation Options"
echo "===================================="

# Check if pdflatex is installed
if command -v pdflatex &> /dev/null; then
    echo "✅ Found pdflatex. Compiling..."
    pdflatex -interaction=nonstopmode project-outcomes.tex
    pdflatex -interaction=nonstopmode project-outcomes.tex  # Run twice for TOC
    echo "✅ PDF generated: project-outcomes.pdf"
    open project-outcomes.pdf 2>/dev/null
    exit 0
fi

# Check if xelatex is installed (better for UTF-8)
if command -v xelatex &> /dev/null; then
    echo "✅ Found xelatex. Compiling..."
    xelatex -interaction=nonstopmode project-outcomes.tex
    xelatex -interaction=nonstopmode project-outcomes.tex  # Run twice for TOC
    echo "✅ PDF generated: project-outcomes.pdf"
    open project-outcomes.pdf 2>/dev/null
    exit 0
fi

# Use Docker if available
if command -v docker &> /dev/null; then
    echo "🐳 Using Docker to compile LaTeX..."
    docker run --rm -v "$PWD":/data -w /data texlive/texlive:latest \
        pdflatex -interaction=nonstopmode project-outcomes.tex
    docker run --rm -v "$PWD":/data -w /data texlive/texlive:latest \
        pdflatex -interaction=nonstopmode project-outcomes.tex
    echo "✅ PDF generated: project-outcomes.pdf"
    open project-outcomes.pdf 2>/dev/null
    exit 0
fi

echo ""
echo "❌ No LaTeX compiler found. Please use one of these options:"
echo ""
echo "1. Install MacTeX (recommended for Mac):"
echo "   brew install --cask mactex"
echo ""
echo "2. Use Docker:"
echo "   docker run --rm -v \"\$PWD\":/data -w /data texlive/texlive:latest pdflatex project-outcomes.tex"
echo ""
echo "3. Use online compiler:"
echo "   - Overleaf: https://www.overleaf.com"
echo "   - ShareLaTeX: https://www.sharelatex.com"
echo ""
echo "4. Use VS Code with LaTeX Workshop extension"
echo ""
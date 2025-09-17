# Contributing to VideoPD

We welcome contributions to the VideoPD project! This document provides guidelines for contributing to the project.

## Code of Conduct

By participating in this project, you agree to abide by our code of conduct:
- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a welcoming environment for all contributors

## How to Contribute

### 1. Fork the Repository

1. Fork the project repository
2. Clone your fork locally
3. Create a new branch for your feature or bug fix

### 2. Development Setup

1. Ensure you have Flutter installed (latest stable version)
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up your environment variables in `.env` file
4. Run the app to ensure everything works:
   ```bash
   flutter run
   ```

### 3. Making Changes

1. Create a descriptive branch name:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

2. Make your changes following our coding standards:
   - Follow Dart/Flutter conventions
   - Add comments for complex logic
   - Ensure proper error handling
   - Write meaningful commit messages

3. Test your changes:
   ```bash
   flutter test
   flutter analyze
   ```

### 4. Submitting Changes

1. Commit your changes with descriptive messages:
   ```bash
   git commit -m "feat: add new feature description"
   # or
   git commit -m "fix: resolve specific bug issue"
   ```

2. Push to your fork:
   ```bash
   git push origin your-branch-name
   ```

3. Create a Pull Request with:
   - Clear title and description
   - Link to any related issues
   - Screenshots if UI changes are involved
   - Test results and verification steps

## Coding Standards

### Dart/Flutter Guidelines

- Use meaningful variable and function names
- Follow Dart naming conventions (camelCase for variables, PascalCase for classes)
- Keep functions small and focused
- Add documentation comments for public APIs
- Use `final` and `const` where appropriate

### File Organization

- Place new widgets in appropriate directories under `lib/`
- Keep related files together
- Use barrel exports (`index.dart`) for cleaner imports

### Error Handling

- Always handle potential errors gracefully
- Provide user-friendly error messages
- Log errors appropriately for debugging

## Pull Request Guidelines

### Before Submitting

- [ ] Code follows project conventions
- [ ] All tests pass
- [ ] No analyzer warnings
- [ ] Documentation is updated if needed
- [ ] Commits are squashed if necessary

### PR Description Template

```markdown
## Summary
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Self-review completed
- [ ] Code follows style guidelines
- [ ] Tests added for new functionality
- [ ] Documentation updated
```

## Issue Reporting

When reporting issues:

1. **Use the issue template** if available
2. **Provide clear reproduction steps**
3. **Include environment details**:
   - Flutter version
   - Device/OS information
   - Relevant logs or error messages
4. **Add labels** appropriately (bug, enhancement, question, etc.)

## Feature Requests

For new features:

1. **Check existing issues** to avoid duplicates
2. **Provide clear use cases** and rationale
3. **Consider implementation approach** if possible
4. **Be open to discussion** about alternative solutions

## Development Guidelines

### AWS S3 Integration

- Always validate AWS credentials before operations
- Handle region-specific errors gracefully
- Implement proper retry logic for network operations
- Maintain consistent error messages

### Firebase Integration

- Follow Firebase best practices
- Handle offline scenarios
- Implement proper data validation

### Security Considerations

- Never commit sensitive credentials
- Validate all user inputs
- Follow security best practices for file handling
- Implement proper access controls

## Getting Help

If you need help:

1. Check existing documentation
2. Search through existing issues
3. Create a new issue with the "question" label
4. Join community discussions if available

## Recognition

Contributors will be acknowledged in:
- Release notes for significant contributions
- Project documentation
- Community highlights

## License

By contributing to this project, you agree that your contributions will be licensed under the Apache-2.0 License.

Thank you for contributing to VideoPD!
/// خيارات السنة الدراسية كما اعتمدتها المدرّسة:
/// الرابعة، الخامسة (نظامية)، الخامسة (تخرج)
enum StudyYearOption {
  fourth('السنة الرابعة', 'fourth', false),
  fifth('السنة الخامسة (نظامية)', 'fifth', false),
  fifthGraduating('السنة الخامسة (سنة تخرج)', 'fifth', true);

  const StudyYearOption(this.label, this.apiValue, this.isGraduating);

  final String label;

  /// القيمة المخزنة في profiles.study_year
  final String apiValue;

  /// القيمة المخزنة في profiles.is_graduating
  final bool isGraduating;
}

import 'package:flutter/material.dart';
import '../../core/models/survey.dart';
import 'survey_assign_dialog.dart';
import 'survey_detail_view.dart';
import 'survey_form_view.dart';
import 'survey_list_view.dart';
import 'survey_statistics_view.dart';

enum _SurveyScreenMode {
  LIST,
  DETAIL,
  FORM,
  STATISTICS,
}

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  _SurveyScreenMode _mode = _SurveyScreenMode.LIST;
  int? _selectedSurveyId;
  SurveyAdminDetail? _editingSurvey;

  void _goToList() {
    setState(() {
      _mode = _SurveyScreenMode.LIST;
      _selectedSurveyId = null;
      _editingSurvey = null;
    });
  }

  void _goToDetail(int id) {
    setState(() {
      _selectedSurveyId = id;
      _mode = _SurveyScreenMode.DETAIL;
    });
  }

  void _goToCreate() {
    setState(() {
      _editingSurvey = null;
      _mode = _SurveyScreenMode.FORM;
    });
  }

  void _goToEdit(SurveyAdminDetail survey) {
    setState(() {
      _editingSurvey = survey;
      _mode = _SurveyScreenMode.FORM;
    });
  }

  void _goToStatistics(int id) {
    setState(() {
      _selectedSurveyId = id;
      _mode = _SurveyScreenMode.STATISTICS;
    });
  }

  void _openAssignDialog(SurveyAdminList survey) {
    showDialog(
      context: context,
      builder: (ctx) => SurveyAssignDialog(
        survey: survey,
        onAssigned: () {
          if (_mode == _SurveyScreenMode.LIST) {
            setState(() {});
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _SurveyScreenMode.DETAIL:
        return SurveyDetailView(
          surveyId: _selectedSurveyId!,
          onBack: _goToList,
          onEdit: (survey) => _goToEdit(survey),
          onAssign: (survey) => _openAssignDialog(survey),
          onViewStats: (id) => _goToStatistics(id),
          onSurveyChanged: () => setState(() {}),
        );

      case _SurveyScreenMode.FORM:
        return SurveyFormView(
          existingSurvey: _editingSurvey,
          onCancel: _goToList,
          onSuccess: _goToList,
        );

      case _SurveyScreenMode.STATISTICS:
        return SurveyStatisticsView(
          surveyId: _selectedSurveyId!,
          onBack: _goToList,
        );

      case _SurveyScreenMode.LIST:
        return SurveyListView(
          onViewDetail: (s) => _goToDetail(s.surveyId),
          onEdit: (s) => _goToEdit(s),
          onAssign: (s) => _openAssignDialog(s),
          onViewStats: (id) => _goToStatistics(id),
          onCreateNew: _goToCreate,
        );
    }
  }
}

import 'package:flutter/material.dart';
import '../../core/models/survey.dart';
import 'dialog/survey_assign_customers_dialog.dart';
import 'editor/survey_editor_view.dart';
import 'result/survey_results_view.dart';
import 'survey_detail_view.dart';
import 'survey_list_view.dart';

enum _SurveyScreenMode {
  list,
  detail,
  form,
  statistics,
}

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  _SurveyScreenMode _mode = _SurveyScreenMode.list;
  _SurveyScreenMode _returnModeAfterSubView = _SurveyScreenMode.list;
  int? _selectedSurveyId;
  SurveyAdminDetail? _editingSurvey;
  int _listRefreshKey = 0;
  int _detailRefreshKey = 0;

  void _goToList() {
    setState(() {
      _mode = _SurveyScreenMode.list;
      _returnModeAfterSubView = _SurveyScreenMode.list;
      _selectedSurveyId = null;
      _editingSurvey = null;
    });
  }

  void _goToDetail(int id) {
    setState(() {
      _selectedSurveyId = id;
      _mode = _SurveyScreenMode.detail;
    });
  }

  void _goToCreate() {
    setState(() {
      _editingSurvey = null;
      _returnModeAfterSubView = _SurveyScreenMode.list;
      _mode = _SurveyScreenMode.form;
    });
  }

  void _goToEdit(SurveyAdminDetail survey, {required bool fromDetail}) {
    setState(() {
      _selectedSurveyId = survey.surveyId;
      _editingSurvey = survey;
      _returnModeAfterSubView =
          fromDetail ? _SurveyScreenMode.detail : _SurveyScreenMode.list;
      _mode = _SurveyScreenMode.form;
    });
  }

  void _goToStatistics(int id, {required bool fromDetail}) {
    setState(() {
      _selectedSurveyId = id;
      _returnModeAfterSubView =
          fromDetail ? _SurveyScreenMode.detail : _SurveyScreenMode.list;
      _mode = _SurveyScreenMode.statistics;
    });
  }

  void _exitSubView() {
    if (_returnModeAfterSubView == _SurveyScreenMode.detail &&
        _selectedSurveyId != null) {
      setState(() {
        _editingSurvey = null;
        _mode = _SurveyScreenMode.detail;
      });
    } else {
      _goToList();
    }
  }

  void _openAssignDialog(SurveyAdminList survey) {
    showDialog(
      context: context,
      builder: (ctx) => SurveyAssignCustomersDialog(
        survey: survey,
        onAssigned: () {
          setState(() {
            _listRefreshKey++;
            if (_selectedSurveyId == survey.surveyId) {
              _detailRefreshKey++;
            }
          });
        },
      ),
    );
  }

  Widget _buildSubView() {
    switch (_mode) {
      case _SurveyScreenMode.detail:
        return SurveyDetailView(
          key: ValueKey('detail_$_selectedSurveyId'),
          surveyId: _selectedSurveyId!,
          onBack: _goToList,
          onEdit: (survey) => _goToEdit(survey, fromDetail: true),
          onAssign: (survey) => _openAssignDialog(survey),
          onViewStats: (id) => _goToStatistics(id, fromDetail: true),
          onSurveyChanged: ({bool reloadDetail = false}) {
            setState(() {
              _listRefreshKey++;
              if (reloadDetail) {
                _detailRefreshKey++;
              }
            });
          },
          refreshTrigger: _detailRefreshKey,
        );

      case _SurveyScreenMode.form:
        final fromDetail = _returnModeAfterSubView == _SurveyScreenMode.detail;
        return SurveyEditorView(
          key: ValueKey('form_${_editingSurvey?.surveyId ?? 'new'}'),
          existingSurvey: _editingSurvey,
          backLabel: fromDetail ? 'Quay lại chi tiết' : 'Quay lại danh sách',
          onCancel: _exitSubView,
          onSuccess: () {
            setState(() {
              _listRefreshKey++;
              if (fromDetail) {
                _detailRefreshKey++;
              }
            });
            _exitSubView();
          },
        );

      case _SurveyScreenMode.statistics:
        final fromDetail = _returnModeAfterSubView == _SurveyScreenMode.detail;
        return SurveyResultsView(
          key: ValueKey('stats_$_selectedSurveyId'),
          surveyId: _selectedSurveyId!,
          backLabel: fromDetail ? 'Quay lại chi tiết' : 'Danh sách khảo sát',
          onBack: _exitSubView,
        );

      case _SurveyScreenMode.list:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _mode == _SurveyScreenMode.list ? 0 : 1,
      children: [
        SurveyListView(
          key: const ValueKey('survey_list_view'),
          onViewDetail: (s) => _goToDetail(s.surveyId),
          onEdit: (s) => _goToEdit(s, fromDetail: false),
          onAssign: (s) => _openAssignDialog(s),
          onViewStats: (id) => _goToStatistics(id, fromDetail: false),
          onCreateNew: _goToCreate,
          refreshTrigger: _listRefreshKey,
        ),
        _buildSubView(),
      ],
    );
  }
}

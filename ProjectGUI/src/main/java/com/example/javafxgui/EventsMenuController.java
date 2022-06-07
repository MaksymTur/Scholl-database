package com.example.javafxgui;

import javafx.beans.property.IntegerProperty;
import javafx.beans.property.ObjectProperty;
import javafx.beans.property.SimpleIntegerProperty;
import javafx.beans.property.SimpleObjectProperty;
import javafx.collections.FXCollections;
import javafx.collections.ListChangeListener;
import javafx.collections.ObservableList;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.control.*;
import javafx.scene.text.Text;
import javafx.stage.Stage;
import javafx.util.Callback;
import javafx.util.Pair;

import java.io.IOException;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.function.Supplier;

import static com.example.javafxgui.HelloApplication.conn;

public class EventsMenuController {
    @FXML DatePicker datePicker;
    @FXML Spinner<Integer> lessonPicker;
    @FXML Text lessonBoundsText;
    final ObjectProperty<LocalDate> chosenDate = new SimpleObjectProperty<>();
    final IntegerProperty chosenLesson = new SimpleIntegerProperty();

    @FXML ComboBox<Integer> defaultScheduleTeacherPicker;
    @FXML Button defaultScheduleLoadButton;
    final IntegerProperty chosenDefaultTeacher = new SimpleIntegerProperty();


    @FXML ComboBox<Integer> teacherPicker;
    @FXML ComboBox<Integer> roomPicker;
    @FXML ComboBox<Integer> subjectPicker;
    @FXML ComboBox<Integer> themePicker;
    final IntegerProperty chosenTeacher = new SimpleIntegerProperty();
    final IntegerProperty chosenRoom = new SimpleIntegerProperty();
    final IntegerProperty chosenSubject = new SimpleIntegerProperty();
    final IntegerProperty chosenTheme = new SimpleIntegerProperty();

    @FXML ListView<Integer> groupsListView;
    @FXML ListView<Integer> pupilsListView;
    @FXML ComboBox<Integer> addGroupPicker;
    @FXML Button addGroupButton;
    final IntegerProperty chosenAddGroup = new SimpleIntegerProperty();
    final ObservableList<Integer> chosenGroups = FXCollections.observableArrayList();

    final IntegerProperty editableEvent = new SimpleIntegerProperty();

    final ObservableList<Integer> lessonsOnDate = FXCollections.observableArrayList();
    final Map<Integer, Pair<LocalTime, LocalTime>> lessonsBounds = new HashMap<>();

    final Map<Integer, String> employeeFullNameById = new HashMap<>();
    final Map<Integer, String> roomNameById = new HashMap<>();
    final Map<Integer, String> subjectNameById = new HashMap<>();
    final Map<Integer, String> themeNameById = new HashMap<>();
    final Map<Integer, String> groupNameById = new HashMap<>();
    final Map<Integer, String> pupilFullNameById = new HashMap<>();

    final ObservableList<Integer> availableDefaultScheduleTeachers = FXCollections.observableArrayList();
    final ObservableList<Integer> availableTeachers = FXCollections.observableArrayList();
    final ObservableList<Integer> availableRooms = FXCollections.observableArrayList();
    final ObservableList<Integer> availableSubjects = FXCollections.observableArrayList();
    final ObservableList<Integer> availableThemes = FXCollections.observableArrayList();
    final ObservableList<Integer> availableGroups = FXCollections.observableArrayList();

    final ObservableList<Integer> groupPupils = FXCollections.observableArrayList();

    void initInfo(){
        try(PreparedStatement st = conn.prepareStatement("SELECT employee_id, CONCAT(first_name, ' ', last_name) FROM employees")) {
            ResultSet res = st.executeQuery();
            employeeFullNameById.clear();
            while (res.next())
                employeeFullNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        try(PreparedStatement st = conn.prepareStatement("SELECT room_id, title FROM rooms")) {
            ResultSet res = st.executeQuery();
            roomNameById.clear();
            while (res.next())
                roomNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        try(PreparedStatement st = conn.prepareStatement("SELECT subject_id, title FROM subjects")) {
            ResultSet res = st.executeQuery();
            subjectNameById.clear();
            while (res.next())
                subjectNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        try(PreparedStatement st = conn.prepareStatement("SELECT theme_id, title FROM themes")) {
            ResultSet res = st.executeQuery();
            themeNameById.clear();
            while (res.next())
                themeNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        try(PreparedStatement st = conn.prepareStatement("SELECT group_id, title FROM \"groups\"")) {
            ResultSet res = st.executeQuery();
            groupNameById.clear();
            while (res.next())
                groupNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        try(PreparedStatement st = conn.prepareStatement("SELECT pupil_id, CONCAT(first_name, ' ', last_name) FROM pupils")) {
            ResultSet res = st.executeQuery();
            pupilFullNameById.clear();
            while (res.next())
                pupilFullNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    {
        initInfo();
    }


    @FXML
    void goToMenu(ActionEvent event) {
        Stage stage = (Stage) ((Node) event.getSource()).getScene().getWindow();
        try {
            Parent root = new FXMLLoader(MainMenuController.class.getResource("main-menu-view.fxml")).load();
            stage.getScene().setRoot(root);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    @FXML
    void onLoadButtonPressed(ActionEvent event){
        try(PreparedStatement st = conn.prepareStatement("SELECT teacher_id, room_id, subject_id FROM get_schedule(?) WHERE bell_order = ? AND teacher_id = ?")){
            st.setDate(1, Date.valueOf(chosenDate.get()));
            st.setInt(2, chosenLesson.get());
            st.setInt(3, chosenDefaultTeacher.get());
            ResultSet res = st.executeQuery();
            if(res.next()){
                teacherPicker.setValue(res.getInt(1));
                roomPicker.setValue(res.getInt(2));
                subjectPicker.setValue(res.getInt(3));
            }
            else throw new RuntimeException();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @FXML
    void OnStartLesson(ActionEvent event){
        try(PreparedStatement st = conn.prepareStatement("INSERT INTO events(event_date, event_bell, teacher_id, room_id, theme_id) VALUES (?, ?, ?, ?, ?) RETURNING event_id")){
            st.setDate(1, Date.valueOf(chosenDate.get()));
            st.setInt(2, chosenLesson.get());
            st.setInt(3, chosenTeacher.get());
            st.setInt(4, chosenRoom.get());
            st.setInt(5, chosenTheme.get());
            ResultSet res = st.executeQuery();
            res.next();
            editableEvent.set(res.getInt(1));
            conn.commit();
        } catch (SQLException e) {
            try {
                conn.rollback();
            } catch (SQLException ex) {
                throw new RuntimeException(ex);
            }
            throw new RuntimeException(e);
        }
    }

    @FXML
    void onGroupAdd(){
        if(!chosenGroups.contains(chosenAddGroup.get()))
            chosenGroups.add(chosenAddGroup.get());
    }

    void updateAvailableDefaultTeachers() {
        try(PreparedStatement st = conn.prepareStatement("SELECT * FROM get_schedule(?) WHERE bell_order = ?")){
            st.setDate(1, Date.valueOf(chosenDate.get()));
            st.setInt(2, chosenLesson.get());
            ResultSet res = st.executeQuery();
            List<Integer> newList = FXCollections.observableArrayList();
            while (res.next())
                newList.add(res.getInt(1));
            availableDefaultScheduleTeachers.setAll(newList);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    void updateAvailableTeachers(){
        try(PreparedStatement st = conn.prepareStatement("SELECT employee_id FROM employees")){
            ResultSet res = st.executeQuery();
            List<Integer> newList = FXCollections.observableArrayList();
            while (res.next())
                newList.add(res.getInt(1));
            availableTeachers.setAll(newList);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    void updateAvailableRooms(){
        try(PreparedStatement st = conn.prepareStatement("SELECT room_id FROM rooms")){
            ResultSet res = st.executeQuery();
            List<Integer> newList = FXCollections.observableArrayList();
            while (res.next())
                newList.add(res.getInt(1));
            availableRooms.setAll(newList);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    void updateAvailableSubjects(){
        try(PreparedStatement st = conn.prepareStatement("SELECT subject_id FROM subjects")){
            ResultSet res = st.executeQuery();
            List<Integer> newList = FXCollections.observableArrayList();
            while (res.next())
                newList.add(res.getInt(1));
            availableSubjects.setAll(newList);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    void updateAvailableThemes(){
        try(PreparedStatement st = conn.prepareStatement("SELECT theme_id FROM themes WHERE subject_id = ?")){
            st.setInt(1, chosenSubject.get());
            ResultSet res = st.executeQuery();
            List<Integer> newList = FXCollections.observableArrayList();
            while (res.next())
                newList.add(res.getInt(1));
            availableThemes.setAll(newList);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    void updateGroups(){
        try(PreparedStatement stAvailable = conn.prepareStatement("SELECT group_id FROM \"groups\"");
            PreparedStatement stChosen = conn.prepareStatement("SELECT group_id FROM groups_to_events WHERE event_id = ?")){
            {
                ResultSet res = stAvailable.executeQuery();
                List<Integer> newList = FXCollections.observableArrayList();
                while (res.next())
                    newList.add(res.getInt(1));
                availableGroups.setAll(newList);
            }
            {
                stChosen.setInt(1, editableEvent.get());
                ResultSet res = stChosen.executeQuery();
                List<Integer> newList = FXCollections.observableArrayList();
                while (res.next())
                    newList.add(res.getInt(1));
                chosenGroups.setAll(newList);
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    boolean isListEmpty(List<?> list){
        return list.isEmpty() || (list.size() == 1 && list.contains(null));
    }

    @FXML
    void initialize() {
        {
            chosenDate.bind(datePicker.valueProperty());
            chosenLesson.bind(lessonPicker.valueProperty());
            chosenDefaultTeacher.bind(defaultScheduleTeacherPicker.valueProperty());
            chosenTeacher.bind(teacherPicker.valueProperty());
            chosenRoom.bind(roomPicker.valueProperty());
            chosenSubject.bind(subjectPicker.valueProperty());
            chosenTheme.bind(themePicker.valueProperty());

            chosenAddGroup.bind(addGroupPicker.valueProperty());
        } // chosen- bindings

        lessonsOnDate.addListener((ListChangeListener<Integer>) c -> lessonPicker.setDisable(isListEmpty(c.getList())));
        lessonPicker.setValueFactory(new SpinnerValueFactory.ListSpinnerValueFactory<>(lessonsOnDate));
        chosenLesson.addListener((observable, oldValue, newValue) -> {
            Pair<LocalTime, LocalTime> p = lessonsBounds.get(newValue.intValue());
            LocalTime from = p.getKey(),
                    to = p.getValue();
            lessonBoundsText.setText("from %s to %s".formatted(from.toString(), to.toString()));
        });
        chosenDate.addListener((observable, oldValue, newValue) -> {
            try (PreparedStatement st = conn.prepareStatement("SELECT * FROM get_bells_schedule(?)")){
                st.setDate(1, Date.valueOf(newValue));
                ResultSet res = st.executeQuery();
                List<Integer> lessons = new ArrayList<>();
                lessonsBounds.clear();
                while (res.next()) {
                    int lesson = res.getInt(1);
                    lessons.add(lesson);
                    lessonsBounds.put(lesson, new Pair<>(res.getTime(2).toLocalTime(), res.getTime(3).toLocalTime()));
                }
                lessonsOnDate.setAll(lessons);
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
        });
        chosenDate.addListener((observable, oldValue, newValue) -> {
            updateAvailableDefaultTeachers();
            updateAvailableTeachers();
            updateAvailableRooms();
            updateAvailableSubjects();
        });
        chosenLesson.addListener((observable, oldValue, newValue) -> {
            updateAvailableDefaultTeachers();
            updateAvailableTeachers();
            updateAvailableRooms();
            updateAvailableSubjects();
        });
        chosenSubject.addListener((observable, oldValue, newValue) -> updateAvailableThemes());
        editableEvent.addListener((observable, oldValue, newValue) -> updateGroups());
        Function<Map<Integer, String>, Supplier<ListCell<Integer>>> cellFactoryBuilder = map -> (() -> new ListCell<>() {
            @Override
            protected void updateItem(Integer item, boolean empty) {
                super.updateItem(item, empty);
                if (item == null || empty) {
                    setGraphic(null);
                } else {
                    setText(map.get(item));
                }
            }
        });
        {
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(employeeFullNameById);
            defaultScheduleTeacherPicker.setButtonCell(cellFactory.get());
            defaultScheduleTeacherPicker.setCellFactory(param -> cellFactory.get());

            availableDefaultScheduleTeachers.addListener((ListChangeListener<Integer>) c -> {
                defaultScheduleTeacherPicker.setDisable(isListEmpty(c.getList()));
                defaultScheduleLoadButton.setDisable(isListEmpty(c.getList()));
            });

            defaultScheduleTeacherPicker.setItems(availableDefaultScheduleTeachers);
        } // defaultScheduleTeacherPicker
        {
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(employeeFullNameById);
            teacherPicker.setButtonCell(cellFactory.get());
            teacherPicker.setCellFactory(param -> cellFactory.get());

            availableTeachers.addListener((ListChangeListener<Integer>) c -> teacherPicker.setDisable(isListEmpty(c.getList())));

            teacherPicker.setItems(availableTeachers);
        } // teacherPicker
        {
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(roomNameById);
            roomPicker.setButtonCell(cellFactory.get());
            roomPicker.setCellFactory(param -> cellFactory.get());

            availableRooms.addListener((ListChangeListener<Integer>) c -> roomPicker.setDisable(isListEmpty(c.getList())));

            roomPicker.setItems(availableRooms);
        } // roomPicker
        {
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(subjectNameById);
            subjectPicker.setButtonCell(cellFactory.get());
            subjectPicker.setCellFactory(param -> cellFactory.get());

            availableSubjects.addListener((ListChangeListener<Integer>) c -> subjectPicker.setDisable(isListEmpty(c.getList())));

            subjectPicker.setItems(availableSubjects);
        } // subjectPicker
        {
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(themeNameById);
            themePicker.setButtonCell(cellFactory.get());
            themePicker.setCellFactory(param -> cellFactory.get());

            availableThemes.addListener((ListChangeListener<Integer>) c -> themePicker.setDisable(isListEmpty(c.getList())));

            themePicker.setItems(availableThemes);
        } // themePicker

        {
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(groupNameById);
            addGroupPicker.setButtonCell(cellFactory.get());
            addGroupPicker.setCellFactory(param -> cellFactory.get());

            availableGroups.addListener((ListChangeListener<Integer>) c -> {
                addGroupPicker.setDisable(isListEmpty(c.getList()));
                addGroupButton.setDisable(isListEmpty(c.getList()));
            });

            addGroupPicker.setItems(availableGroups);
        } // addGroupPicker

        {
            Supplier<ListCell<Integer>> cellFactory = () -> new ListCell<>() {

                Integer item;

                {
                    this.setOnMouseClicked(event -> {
                        if(event.getClickCount() >= 2 && item != null)
                            chosenGroups.remove(item);
                        groupsListView.refresh();
                    });
                }

                @Override
                protected void updateItem(Integer item, boolean empty) {
                    super.updateItem(item, empty);
                    this.item = item;
                    if (item == null || empty) {
                        setText(null);
                    } else {
                        setText(groupNameById.get(item));
                    }
                }
            };
            groupsListView.setCellFactory(param -> cellFactory.get());

            groupsListView.setItems(chosenGroups);

        }

        chosenGroups.addListener((ListChangeListener<Integer>) c -> {
            while(c.next()) {
                if (c.wasAdded()) {
                    for(Integer group : c.getAddedSubList()){
                       try(PreparedStatement st = conn.prepareStatement("INSERT INTO groups_to_events(group_id, event_id) VALUES (?, ?)")){
                           st.setInt(1, group);
                           st.setInt(2, editableEvent.get());
                           st.executeUpdate();
                           conn.commit();
                       } catch (SQLException e) {
                           try{
                               conn.rollback();
                           } catch (SQLException ex) {
                               throw new RuntimeException(ex);
                           }
                           throw new RuntimeException(e);
                       }
                    }
                }
                if (c.wasRemoved()){
                    for(Integer group : c.getRemoved()){
                        try(PreparedStatement st = conn.prepareStatement("DELETE FROM groups_to_events WHERE group_id = ? AND event_id = ?")){
                            st.setInt(1, group);
                            st.setInt(2, editableEvent.get());
                            st.executeUpdate();
                            conn.commit();
                        } catch (SQLException e) {
                            try{
                                conn.rollback();
                            } catch (SQLException ex) {
                                throw new RuntimeException(ex);
                            }
                            throw new RuntimeException(e);
                        }
                    }
                }
            }
        });
    }
}

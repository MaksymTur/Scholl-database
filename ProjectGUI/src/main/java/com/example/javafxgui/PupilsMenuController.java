package com.example.javafxgui;

import javafx.collections.FXCollections;
import javafx.collections.MapChangeListener;
import javafx.collections.ObservableList;
import javafx.collections.ObservableMap;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.control.ComboBox;
import javafx.scene.control.DatePicker;
import javafx.scene.control.ListCell;
import javafx.scene.control.TextField;
import javafx.stage.Stage;

import java.io.IOException;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;
import java.util.function.Function;
import java.util.function.Supplier;

import static com.example.javafxgui.HelloApplication.conn;

public class PupilsMenuController {

    @FXML
    TextField firstNameField;
    @FXML
    TextField lastNameField;
    @FXML
    DatePicker birthDatePicker;

    @FXML
    ComboBox<Integer> pupilPicker;
    @FXML
    ComboBox<Integer> classPicker;
    @FXML
    ComboBox<Integer> groupPicker;

    final ObservableList<Integer> pupils = FXCollections.observableArrayList();
    final ObservableList<Integer> classes = FXCollections.observableArrayList();
    final ObservableList<Integer> groups = FXCollections.observableArrayList();
    final ObservableMap<Integer, String> pupilNameById = FXCollections.observableHashMap();
    final ObservableMap<Integer, String> classNameById = FXCollections.observableHashMap();
    final ObservableMap<Integer, String> groupNameById = FXCollections.observableHashMap();

    void initInfo() {
        try (PreparedStatement st = conn.prepareStatement("SELECT pupil_id, CONCAT(first_name, ' ', last_name) FROM pupils")) {
            ResultSet res = st.executeQuery();
            while (res.next())
                pupilNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        try (PreparedStatement st = conn.prepareStatement("SELECT class_id, CONCAT(study_year::text, title) FROM classes")) {
            ResultSet res = st.executeQuery();
            while (res.next())
                classNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        try (PreparedStatement st = conn.prepareStatement("SELECT group_id, title FROM \"groups\"")) {
            ResultSet res = st.executeQuery();
            while (res.next())
                groupNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    {
        pupilNameById.addListener((MapChangeListener<Integer, String>) change -> {
            if (change.wasAdded())
                pupils.add(change.getKey());
            else pupils.remove(change.getKey());
        });
        classNameById.addListener((MapChangeListener<Integer, String>) change -> {
            if (change.wasAdded())
                classes.add(change.getKey());
            else classes.remove(change.getKey());
        });
        groupNameById.addListener((MapChangeListener<Integer, String>) change -> {
            if (change.wasAdded())
                groups.add(change.getKey());
            else groups.remove(change.getKey());
        });
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
    void addPupil(ActionEvent event) {
        String firstName = firstNameField.getText();
        String lastName = lastNameField.getText();
        try (PreparedStatement st = conn.prepareStatement("INSERT INTO pupils(first_name, last_name, date_of_birth) VALUES (?, ?, ?) RETURNING pupil_id")) {
            st.setString(1, firstName);
            st.setString(2, lastName);
            st.setDate(3, Date.valueOf(birthDatePicker.getValue()));
            ResultSet res = st.executeQuery();
            res.next();
            int id = res.getInt(1);
            pupilNameById.put(id, firstName + " " + lastName);
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
    void movePupilToClass(ActionEvent event) {
        try (PreparedStatement st = conn.prepareStatement("INSERT INTO class_history(pupil_id, class_id) VALUES (?, ?)")) {
            st.setInt(1, pupilPicker.getValue());
            st.setInt(2, classPicker.getValue());
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

    @FXML
    void addPupilToGroup(ActionEvent event) {
        try (PreparedStatement st = conn.prepareStatement("INSERT INTO groups_history(pupil_id, group_id) VALUES (?, ?)")) {
            st.setInt(1, pupilPicker.getValue());
            st.setInt(2, groupPicker.getValue());
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

    @FXML
    void removePupilFromGroup(ActionEvent event) {
        System.out.println("DOESN'T WORK");
    }

    @FXML
    void initialize() {
        {
            pupilPicker.setItems(pupils);
            classPicker.setItems(classes);
            groupPicker.setItems(groups);
        }

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
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(pupilNameById);
            pupilPicker.setCellFactory(param -> cellFactory.get());
            pupilPicker.setButtonCell(cellFactory.get());
        }

        {
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(classNameById);
            classPicker.setCellFactory(param -> cellFactory.get());
            classPicker.setButtonCell(cellFactory.get());
        }

        {
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(groupNameById);
            groupPicker.setCellFactory(param -> cellFactory.get());
            groupPicker.setButtonCell(cellFactory.get());
        }
    }
}

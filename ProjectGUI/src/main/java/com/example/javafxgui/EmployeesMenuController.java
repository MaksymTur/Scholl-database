
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

public class EmployeesMenuController {

    @FXML
    TextField firstNameField;
    @FXML
    TextField lastNameField;

    @FXML
    ComboBox<Integer> employeePicker;
    @FXML
    TextField salaryField;
    @FXML
    ComboBox<Integer> postPicker;

    final ObservableList<Integer> employees = FXCollections.observableArrayList();
    final ObservableList<Integer> posts = FXCollections.observableArrayList();
    final ObservableMap<Integer, String> employeeNameById = FXCollections.observableHashMap();
    final ObservableMap<Integer, String> postNameById = FXCollections.observableHashMap();

    void initInfo() {
        try (PreparedStatement st = conn.prepareStatement("SELECT employee_id, CONCAT(first_name, ' ', last_name) FROM employees")) {
            ResultSet res = st.executeQuery();
            while (res.next())
                employeeNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        try (PreparedStatement st = conn.prepareStatement("SELECT post_id, title FROM posts")) {
            ResultSet res = st.executeQuery();
            while (res.next())
                postNameById.put(res.getInt(1), res.getString(2));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    {
        employeeNameById.addListener((MapChangeListener<Integer, String>) change -> {
            if (change.wasAdded())
                employees.add(change.getKey());
            else employees.remove(change.getKey());
        });
        postNameById.addListener((MapChangeListener<Integer, String>) change -> {
            if (change.wasAdded())
                posts.add(change.getKey());
            else posts.remove(change.getKey());
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
    void addEmployee(ActionEvent event) {
        String firstName = firstNameField.getText();
        String lastName = lastNameField.getText();
        try (PreparedStatement st = conn.prepareStatement("INSERT INTO employees(first_name, last_name) VALUES (?, ?) RETURNING employee_id")) {
            st.setString(1, firstName);
            st.setString(2, lastName);
            ResultSet res = st.executeQuery();
            res.next();
            int id = res.getInt(1);
            employeeNameById.put(id, firstName + " " + lastName);
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
    void setSalary(ActionEvent event) {
        try (PreparedStatement st = conn.prepareStatement("INSERT INTO salary_history(employee_id, salary) VALUES (?, ?)")) {
            st.setInt(1, employeePicker.getValue());
            st.setInt(2, Integer.parseInt(salaryField.getText()));
            st.executeUpdate();
            conn.commit();
        } catch (NumberFormatException ignore) {
            try{
                conn.rollback();
            } catch (SQLException ex) {
                throw new RuntimeException(ex);
            }
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
    void addPost(ActionEvent event) {
        try (PreparedStatement st = conn.prepareStatement("SELECT add_post(?, ?)")) {
            st.setInt(1, employeePicker.getValue());
            st.setInt(2, postPicker.getValue());
            st.executeQuery();
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
    void removePost(ActionEvent event) {
        try (PreparedStatement st = conn.prepareStatement("SELECT delete_post(?, ?)")) {
            st.setInt(1, employeePicker.getValue());
            st.setInt(2, postPicker.getValue());
            st.executeQuery();
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
    void initialize() {
        {
            employeePicker.setItems(employees);
            postPicker.setItems(posts);
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
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(employeeNameById);
            employeePicker.setCellFactory(param -> cellFactory.get());
            employeePicker.setButtonCell(cellFactory.get());
        }

        {
            Supplier<ListCell<Integer>> cellFactory = cellFactoryBuilder.apply(postNameById);
            postPicker.setCellFactory(param -> cellFactory.get());
            postPicker.setButtonCell(cellFactory.get());
        }
    }
}

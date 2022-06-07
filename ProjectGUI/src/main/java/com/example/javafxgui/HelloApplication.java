package com.example.javafxgui;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;
import java.sql.*;

import java.io.IOException;

public class HelloApplication extends Application {

    public static Connection conn;

    @Override
    public void start(Stage stage) throws IOException {
        FXMLLoader fxmlLoader = new FXMLLoader(HelloApplication.class.getResource("main-menu-view.fxml"));
        Scene scene = new Scene(fxmlLoader.load(), 1280, 720);
        stage.setTitle("Hello!");
        stage.setScene(scene);
        stage.show();
    }

    public static void main(String[] args) {
        String url = "jdbc:postgresql://localhost:5432/postgres";
        try(Connection c = DriverManager.getConnection(url, "postgres", "31415")){
            conn = c;
            conn.setAutoCommit(false);
            launch();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}